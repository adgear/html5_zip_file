require 'rubygems'

require 'pathname'

require 'html5_zip_file/zip_unpack'

module HTML5ZipFile
  Error = Class.new(StandardError)

  DestinationError  = Class.new(Error)
  InexistentError = Class.new(DestinationError)
  NotEmptyError = Class.new(DestinationError)

  class File
    private_class_method :new

    # Instantiate an {File} object and yield it to a block supplied by
    # the caller.
    #
    # Within the block, you can call {#validate} and {#unpack} on the
    # object.
    #
    # You can also call {#size_packed}, {#size_unpacked}, {#entries},
    # {#file_entries}, {#directory_entries} and {#html_file_entries}.
    #
    # Note: if corruption is detected, an {File} object is
    # still yielded to the block, but its {#validate} method always
    # returns false and its {#unpack} method raises {ZipUnpack::CorruptZipFileError}.
    #
    # @param [String] file_name file name of zip file
    #
    # @yieldparam f [HTML5ZipFile::File]
    # @return [void]
    #
    # @example Open a zip file
    #
    #   HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|
    #     puts "entries:"
    #     f.entries.each { |e| puts(e.inspect()) }
    #   end #=> nil
    def self.open(file_name)
      yield new(ZipUnpack::InfoZipFile.new(file_name))
      nil
    rescue ZipUnpack::CorruptZipFileError
      yield new(ZipUnpack::CorruptZipFile.new)
      nil
    end

    # Failures detected by the last invocation of {#validate}
    #
    # @return [Array] validation failure keywords
    attr_reader :failures

    # Validate zip file
    #
    # If the zip file is corrupt, {#failures} will contain :zip.
    #
    # If any validation checks fail, their keys will be in {#failures}.
    #
    # @param [Hash] opts Presence of a key activates a particular check and value defines the threshold
    #
    # @option opts [Number] :size_packed maximum total size of packed zip file in bytes
    # @option opts [Number] :size_unpacked maximum total size of unpacked contents in bytes
    #
    # @option opts [Number] :entry_count maximum number of files and directories
    # @option opts [Number] :file_count maximum number of files
    # @option opts [Number] :directory_count maximum number of directories
    #
    # @option opts [Number] :path_length maximum path length in characters
    # @option opts [Number] :path_components maximum number of path components
    #
    # @option opts [Boolean] :contains_html_file require or disallow HTML files
    #
    # @return [Boolean] false if the zip file is corrupt or if any validation checks fail
    #
    # @example Validate a zip file
    #
    #   HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|
    #
    #     if f.validate( :size_unpacked => 3, :file_count => 3)
    #       puts 'Passed validation checks.'
    #     else
    #       if f.failures.include? :zip
    #         puts 'File is not a valid zip file.'
    #       end
    #       puts 'Failed validation checks: '
    #       f.failures.each { |failure|  puts(failure) }
    #     end
    #
    #   end #=> nil

    def validate(opts = {})
      @failures = []

      if @zip_file.class == ZipUnpack::CorruptZipFile
        @failures << :zip
        return false
      end

      if opts.key? :size_packed
        @failures << :size_packed unless size_packed <= opts[:size_packed]
      end

      if opts.key? :size_unpacked
        @failures << :size_unpacked unless size_unpacked <= opts[:size_unpacked]
      end

      if opts.key? :entry_count
        @failures << :entry_count unless entries.size <= opts[:entry_count]
      end
      if opts.key? :file_count
        @failures << :file_count unless file_entries.size <= opts[:file_count]
      end
      if opts.key? :directory_count
        @failures << :directory_count unless
          directory_entries.size <= opts[:directory_count]
      end

      if opts.key? :path_length
        @failures << :path_length unless entries.all? do |entry|
          entry.name.size <= opts[:path_length]
        end
      end
      if opts.key? :path_components
        @failures << :path_components unless entries.all? do |entry|
          components = []
          Pathname.new(entry.name).each_filename { |c| components << c }
          components.count <= opts[:path_components]
        end
      end

      if opts.key? :contains_html_file
        @failures << :contains_html_file unless
          html_file_entries.any? == opts[:contains_html_file]
      end

      @failures.none?
    end

    # Unpack the zip file to destination
    #
    # @param [String] destination path to an empty directory
    #
    # @return [void]
    #
    # @raise [DestinationError] if directory does not exist or is not empty
    # @raise [ZipUnpack::CorruptZipFileError] if zip file is corrupt
    #
    # @example Unpack a zip file
    #   HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|
    #
    #      Dir.mktmpdir("HTML5ZipFile_extract_") do |dir|
    #        f.unpack(dir)
    #        puts dir
    #        puts Dir.entries(dir)
    #      end
    #
    #   end #=> nil
    def unpack(destination)
      # raise InexistentError if !Dir.exists?(destination)
      # @deprecated ruby 1.8.7 compat
      begin
        Dir.new(destination)
      rescue SystemCallError
        raise InexistentError
      end

      raise NotEmptyError, "Directory not empty (#{destination})." if
        Dir.entries(destination).size > 2

      @zip_file.unpack(destination)
    end

    # @return [Number] total size of packed zip file in bytes

    def size_packed
      @zip_file.size_packed
    end

    # @return [Number] total size of unpacked contents in bytes

    def size_unpacked
      @size_unpacked ||= file_entries.reduce(0) { |memo, entry| memo + entry.size  }
    end

    # @return [Array<ZipUnpack::Entry>] files and directories in the zip file

    def entries
      @zip_file.entries
    end

    # @return [Array<ZipUnpack::Entry>] files in the zip file

    def file_entries
      @file_entries ||= entries.select do |entry|
        entry.ftype == :file
      end
    end

    # @return [Array<ZipUnpack::Entry>] directories in the zip file

    def directory_entries
      @directory_entries ||= entries.select do |entry|
        entry.ftype == :directory
      end
    end

    # @return [Array<ZipUnpack::Entry>] html files in the zip file

    def html_file_entries
      @html_file_entries ||= file_entries.select do |entry|
        entry.name =~ /\.html?\z/i
      end
    end

    private

    def initialize(zip_file)
      @zip_file = zip_file
    end

  end
end
