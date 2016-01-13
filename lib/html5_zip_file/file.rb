require 'fileutils'
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

      if options.has_key? :contents_size
        @failures << :contents_size unless is_valid_contents_size? options[:contents_size]
      end

      if options.has_key? :entry_count
        @failures << :entry_count unless is_valid_entry_count? options[:entry_count]
      end

      if options.has_key? :file_count
        @failures << :file_count unless is_valid_file_count? options[:file_count]
      end

      if options.has_key? :directory_count
        @failures << :directory_count unless is_valid_directory_count? options[:directory_count]
      end

      if options.has_key? :path_length
        @failures << :path_length unless is_valid_path_length? options[:path_length]
      end

      if options.has_key? :path_components
        @failures << :path_components unless is_valid_path_components? options[:path_components]
      end

      if options.has_key? :contains_html_file
        @failures << :contains_html_file unless contains_html_file? == options[:contains_html_file]
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
      exists = Dir.exists?(dest)
      if exists && Dir.entries(dest).size > 2
        raise DestinationNotEmpty, 'Destination directory is not empty'
      end
      FileUtils.mkdir_p(dest) unless exists

      @unpack_dest = dest

      @zip.each do |entry|
        entry.extract(::File.join(dest, entry.name))
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


  end
end
