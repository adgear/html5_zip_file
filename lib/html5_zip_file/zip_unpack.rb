require 'logger'

require 'rubygems'
require 'html5_zip_file/subprocess'

# https://www.pkware.com/support/zip-app-note/
# https://en.wikipedia.org/wiki/Zip_(file_format)
# https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html

module ZipUnpack

  Error = Class.new(StandardError)

  CorruptZipFileError = Class.new(Error)

  class Entry
    include Comparable
    attr_reader :ftype, :name, :size
    def initialize(ftype, name, size)
      @ftype = ftype
      @name = name
      @size = size
    end
    def <=>(another)
      name <=> another.name
    end
  end

  # @abstract
  class ZipFile

    @@log = Logger.new(STDOUT)
    @@log.level = Logger::INFO

    attr_reader :entries

    def initialize
      @name = ''
      @entries = []
    end

    def size_packed
      0
    end

    def unpack(dest)
      nil
    end

    def self.set_log_level(level)
      @@log.level = level
    end

  end

  class CorruptFile < ZipFile
    def initialize
      super()
    end
  end

  class InfoZipFile < ZipFile

    InfoZipError = Class.new(StandardError)

    UnzipBinaryNotFoundException = Class.new(InfoZipError)
    UnzipBinaryBadVersionException = Class.new(InfoZipError)

    ParsingException = Class.new(InfoZipError)

    # Compatible Info-ZIP versions
    VERSION_WHITELIST = ['UnZip 5.52', 'UnZip 6.0']

    # @raise [UnzipBinaryNotFoundException] unzip binary not found
    # @raise [UnzipBinaryBadVersionException] unzip binary is wrong versions
    # @raise [ParsingException] unable to interpret output from unzip command
    #
    # @raise [CorruptZipFileError] the zip file is corrupt
    def initialize(filename)
      super()

      @name = filename

      # Set up sandbox

      # Check unzip command presence & version
      ver = get_infozip_version
      @@log.info "Info-ZIP: found version #{ver}"

      # Check zip file integrity
      fail CorruptZipFileError unless crc_valid?(filename)
      @@log.info 'Info-ZIP: CRC check passed'

      # Get zip file entries
      @entries = get_entries(filename)
      fail CorruptZipFileError unless @entries
      @@log.info 'Info-ZIP: entries parsed'
    end

    def size_packed
      @packed_size ||= File.size(@name)
    end

    # Warning: user-provided zip files should always be unpacked in a sandbox
    #
    # @todo test "should raise exception if results don't match manifest"

    def unpack(dest)
      @@log.info "Info-ZIP: unpacking to #{dest}"

      # sandbox here.

      exit_code, stdout, stderr = Subprocess::popen('unzip', '-d', dest, @name)
      fail CorruptZipFileError, "Unzip failed" if exit_code != 0

      @@log.info "Info-ZIP: unpack succeeded"
    end

    private

    def get_infozip_version
      exit_code, stdout = Subprocess.popen('unzip', '-v')
      fail UnzipBinaryNotFoundException unless exit_code == 0
      ver = parse_infozip_version(stdout)
      fail UnzipBinaryBadVersionException if ver == false
      ver
    end

    # @return [String] version_string if whitelisted version_string found
    # @return [false] if whitelisted version_string not found

    def parse_infozip_version(stdout)
      VERSION_WHITELIST.each do |ver|
        return ver if Regexp.new('\A' + ver) =~ stdout
      end
      false
    end

    # Extract the files in memory and compare the CRC of each
    # expanded file with the original file's stored CRC value.
    #
    # @TODO: test memory/cpu behavior on zip bombs

    def crc_valid?(name)
      exit_code, stdout = Subprocess.popen('unzip', '-t', name)
      exit_code == 0
    end

    # Get zip file entries
    #
    # @return [Array<Entry>] array of entries
    # @return [false] zip file is corrupt
    #
    #@TODO: test memory/cpu behavior on zip bombs

    def get_entries(name)
      exit_code, stdout = Subprocess.popen('unzip', '-l', name)
      exit_code == 0 ? parse_entries(stdout) : false
    end

    def parse_entries(stdout)
      lines = stdout.split("\n")
      fail ParsingException, 'unzip -l output has too few lines.' \
                             if lines.size < 5
      entry_lines = lines.slice(3, lines.count - 5)
      entries = []
      entry_lines.each do |entry_line|
        if /^\s*(\d+)\s+\d+-\d+-\d+\s+\d+:\d+\s+(.+)$/ =~ entry_line
          entry_size = $1.to_i
          entry_name = $2
          if entry_name[-1, 1] == '/'
            fail ParsingException, "Directory entry with non-zero size." if entry_size != 0
            entries << Entry.new(:directory, entry_name, entry_size)
          else
            entries << Entry.new(:file, entry_name, entry_size)
          end
        else
          fail ParsingException, 'Bad entry line.'
        end
      end
      entries
    end

  end

end
