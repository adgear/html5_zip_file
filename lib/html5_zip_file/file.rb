require "open-uri"
require "tempfile"
require "zip"
require "fileutils"
require "nokogiri"

module HTML5ZipFile
  class File
    # The size of the zip archive.
    attr_accessor :file_size

    # Contains the validation errors.
    attr_accessor :errors

    # Initialize a zip file.
    #
    # path: the path of the zip file (can be a path or a URI)
    # validation_opts: the options for validating this zip file.
    #
    # They are:
    #
    # max_size: the maximum size in bytes of the zip file.
    # max_nb_files: the maximum number of files in the archive.
    # max_nb_dirs: the maximum number of directories in the archive.
    # max_nb_entries: the maximum number of entries in the archive.
    def initialize(path, validation_opts = {})
      @validation_opts = {
        :max_size => 0,
        :max_nb_files => 0,
        :max_nb_dirs => 0,
        :max_nb_entries => 0
      }.merge(validation_opts)

      @path = path

      begin
        file_content = open(path).read
      rescue
        raise FileNotFound, "The zip archive could not be found."
      end

      @temp_file = Tempfile.new('zip')
      @temp_file.write file_content
      @file_size = @temp_file.size
      unless is_valid_zip?
        fail InvalidZipArchive, "Not a valid zip file"
      end
      @zip_file = Zip::File.open(@temp_file.path)

      # Tracks the destination of the last unpack operation.
      @last_unpack_dest = nil
      @errors = [];
    end

    # Does this zip file respect the validation conditions?
    #
    # Returns true or false
    def validate
      is_valid = true
      errors.clear

      if html_files.size == 0
        is_valid = false
        errors << "There are no HTML files in the zip archive."
      end

      if @validation_opts[:max_size] > 0
        if @file_size > @validation_opts[:max_size]
          is_valid = false
          errors << "The zip archive is too big."
        end
      end

      if @validation_opts[:max_nb_files] > 0
        if files.size > @validation_opts[:max_nb_files]
          is_valid = false
          errors << "There are too many files in the zip archive."
        end
      end

      if @validation_opts[:max_nb_dirs] > 0
        if directories.size > @validation_opts[:max_nb_dirs]
          is_valid = false
          errors << "There are too many directories in the zip archive."
        end
      end

      if @validation_opts[:max_nb_entries] > 0
        if content.size > @validation_opts[:max_nb_entries]
          is_valid = false
          errors << "There are too many entries in the zip archive."
        end
      end

      is_valid
    end

    def is_valid?
      errors.empty?
    end

    # Returns the content of the zip file, meaning both files and directories.
    def content
      @zip_file.entries
    end

    # Returns only the files of the zip.
    def files
      files = []
      @zip_file.each do |entry|
        next if entry.ftype == :directory
        files << entry
      end
      files
    end

    # Returns only the directories of the zip.
    def directories
      directories = []
      @zip_file.each do |entry|
        next if entry.ftype == :file
        directories << entry
      end
      directories
    end

    # Returns only the html files.
    def html_files
      regexp = /\.html?\z/i
      entries = []
      @zip_file.each do |entry|
        next if entry.ftype == :directory
        entries << entry if entry.name =~ regexp
      end
      entries
    end

    # Returns the estimated size of the content of the zip when uncompressed.
    def estimated_size
      estimated_size = 0
      @zip_file.each do |entry|
        if entry.ftype == :file
          estimated_size += entry.size
        end
      end
      estimated_size
    end

    # Unpacks the zip file to dest. If dest exists, it must be empty. If it
    # does not exist, it will be created.
    def unpack(dest)
      if dest[-1, 1] != '/'
        dest = "#{dest}/"
      end

      dir_exists = Dir.exists?(dest)
      if dir_exists && Dir.entries(dest).size > 2
        raise DestinationIsNotEmpty, "Destination directory is not empty."
      end

      unless dir_exists
        FileUtils.mkdir_p(dest)
      end

      # Store the destination for use in #destroy_unpacked
      @last_unpack_dest = dest

      @zip_file.each do |entry|
        entry.extract("#{dest}#{entry.name}")
      end
    end

    # Deletes the content of the last unpack operation
    def destroy_unpacked
      return unless Dir.exists?(@last_unpack_dest)
      dest = @last_unpack_dest
      FileUtils.rm_rf(Dir.glob("#{dest}*"))
    end

    # Inserts the script tag in the html documents that were previously
    # unpacked.
    def insert_script_tag(script_tag)
      html_docs = html_files.map { |f| f.name }
    end

    # Closes all files that were opened for the operation of this gem.
    def close
      @temp_file.close
      @zip_file.close
    end

    private

    def is_valid_zip?
      output = `file #{@temp_file.path}`
      output.include? "Zip archive data"
    end
  end
end
