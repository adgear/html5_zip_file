require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'zip'

module HTML5ZipFile
  class File
    # Array of validation failure keywords.
    attr_reader :failures

    # Open a zip file by path.
    def self.open(file_name)
      Zip::File.open(file_name, 0) do |z|
        yield File.new(z)
      end
    rescue Zip::Error
      yield File.new(nil)
    end

    def initialize(zip) # :nodoc:
      @zip = zip
    end

    # Validate zip file with options:
    #
    # - +:contents_size+:: maximum contents size
    # - +:entry_count+:: maximum number of entries (files and directories)
    # - +:file_count+:: maximum number of file
    # - +:directory_count+:: maximum number of directories
    # - +:path_length+:: maximum path length in characters
    # - +:path_components+:: maximum number of path components
    # - +:contains_html_file+:: require or disallow HTML files to exist
    # - +:contains_zip_file+:: require or disallow embedded zip files to exist
    # - +:forbidden_characters:: disallow characters that match this regexp in any entry
    #
    # Populates #failures with keywords of failed validations. If file is not
    # a valid zip, #failures will contain +:zip+.
    #
    # Returns +true+ if validations passed.
    def validate(options = {})
      @failures = []

      unless is_valid_zip?
        @failures << :zip
        return false
      end

      if options.has_key?(:contents_size) && !(is_valid_contents_size? options[:contents_size])
        @failures << :contents_size
      end

      @failures << :entry_count if options.has_key?(:entry_count) && !(is_valid_entry_count? options[:entry_count])

      @failures << :file_count if options.has_key?(:file_count) && !(is_valid_file_count? options[:file_count])

      if options.has_key?(:directory_count) && !(is_valid_directory_count? options[:directory_count])
        @failures << :directory_count
      end

      @failures << :path_length if options.has_key?(:path_length) && !(is_valid_path_length? options[:path_length])

      if options.has_key?(:path_components) && !(is_valid_path_components? options[:path_components])
        @failures << :path_components
      end

      if options.has_key?(:contains_html_file) && !(contains_html_file? == options[:contains_html_file])
        @failures << :contains_html_file
      end

      if options.has_key?(:contains_zip_file) && !(contains_zip_file? == options[:contains_zip_file])
        @failures << :contains_zip_file
      end

      if options.has_key?(:forbidden_characters) && (forbidden_characters? options[:forbidden_characters])
        @failures << :forbidden_characters
      end

      @failures.none?
    end

    # Return total size of zip file contents.
    def contents_size
      @contents_size ||= file_entries.map(&:size).reduce(0, :+)
    end

    # Return all entries.
    def entries
      @zip.entries
    end

    # Return file entries.
    def file_entries
      @file_entries ||= @zip.select do |entry|
        entry.ftype == :file
      end
    end

    # Return directory entries.
    def directory_entries
      @directory_entries ||= @zip.select do |entry|
        entry.ftype == :directory
      end
    end

    # Return HTML file entries.
    def html_file_entries
      @html_file_entries ||= file_entries.select do |entry|
        entry.name =~ /\.html?\z/i
      end
    end

    # Unpack the zip file to +dest+, which must either be an empty directory
    # or not exist.
    #
    # If the destination is not empty, raises #DestinationNotEmpty.
    def unpack(dest)
      exists = Dir.exist?(dest)
      raise DestinationNotEmpty, 'Destination directory is not empty' if exists && Dir.entries(dest).size > 2

      FileUtils.mkdir_p(dest) unless exists

      @unpack_dest = dest

      @zip.each do |entry|
        entry.extract(::File.join(dest, entry.name))
      end
    end

    # Destroy previously unpacked contents.
    def destroy_unpacked
      return unless @unpack_dest && Dir.exist?(@unpack_dest)

      FileUtils.remove_entry_secure(@unpack_dest, force: true)
      @unpack_dest = nil
    end

    # Inject a script tag into alll unpacked HTML files, replacing any
    # previously injected script tag.
    #
    # Raises #NotUnpacked if #unpack has not been called.
    # Raises #InvalidScriptTag if +script_tag+ does not contain a valid tag.
    def inject_script_tag(script_tag)
      raise NotUnpacked, 'Zip file not unpacked' unless @unpack_dest

      html_file_entries.each do |entry|
        path = ::File.join(@unpack_dest, entry.name)

        data = ::File.read(path)
        html = Nokogiri::HTML.parse("<!DOCTYPE html>\n" + data)

        script_fragment = Nokogiri::HTML.fragment(script_tag)
        tag = script_fragment.at_css('script')
        raise InvalidScriptTag, 'Script tag missing' unless tag

        tag['data-adgear-html5'] = 'true'

        if (existing_tag = html.at_css('script[data-adgear-html5="true"]'))
          existing_tag.replace(tag)
        elsif (head_tag = html.at_css('head'))
          head_tag.prepend_child(tag)
        elsif (html_tag = html.at_css('html'))
          html_tag.prepend_child(tag)
        else
          html.prepend_child(tag)
        end

        ::File.write(path, html.to_s)
      end
    end

    private

    def is_valid_zip?
      !!@zip
    end

    def is_valid_contents_size?(max)
      contents_size <= max
    end

    def is_valid_entry_count?(max)
      @zip.size <= max
    end

    def is_valid_file_count?(max)
      file_entries.size <= max
    end

    def is_valid_directory_count?(max)
      directory_entries.size <= max
    end

    def is_valid_path_length?(max)
      @zip.all? do |entry|
        entry.name.size <= max
      end
    end

    def is_valid_path_components?(max)
      @zip.all? do |entry|
        Pathname.new(entry.name).each_filename.count <= max
      end
    end

    def contains_html_file?
      html_file_entries.any?
    end

    def contains_zip_file?
      zip_file_entries.any?
    end

    def forbidden_characters?(chars)
      entries.map(&:name).any? do |name|
        Pathname.new(name).each_filename.any? do |component|
          component.match(chars)
        end
      end
    end

    def zip_file_entries
      @zip_file_entries ||= file_entries.select do |entry|
        entry.name =~ /\.zip\z/i
      end
    end
  end
end
