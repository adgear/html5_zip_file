require 'logger'

require 'rubygems'
require 'posix/spawn'

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

  # Methods that use POSIX::Spawn to run external processes
  # ({#initialize} and {#unpack}) may raise the following exceptions:
  #
  # @raise [POSIX::Spawn::MaximumOutputExceeded] if output length > SPAWN_CHILD_OPTS:max bytes
  # @raise [POSIX::Spawn::TimeoutExceeded] execution time > SPAWN_CHILD_OPTS:timeout seconds
  class ZipFile

    # Compatible Info-ZIP versions
    VERSION_WHITELIST = ['UnZip 5.52', 'UnZip 6.0']

    # Security limits for POSIX::Spawn::Child
    SPAWN_CHILD_OPTS = {
      :max => 300_000,
      :timeout => 20
    }

    ZipFileError = Class.new(StandardError)
    UnzipBadVersionError = Class.new(ZipFileError)
    UnzipParsingError = Class.new(ZipFileError)

    @@log = Logger.new(STDOUT)
    @@log.level = Logger::WARN

    def self.set_log_level(level)
      @@log.level = level
    end

    # @raise [Errno::ENOENT] unzip command line binary not found in $PATH
    # @raise [UnzipBadVersionError] unzip version string not whitelisted
    # @raise [UnzipParsingError] unable to parse output from unzip command
    #
    # @raise [CorruptZipFileError] the zip file is corrupt
    def initialize(filename)
      @filename = filename
      @entries = []

      # Check unzip command presence & version
      ver = get_infozip_version
      @@log.info "Info-ZIP: found version #{ver}"

      # Check zip file integrity
      raise CorruptZipFileError unless crc_valid?(filename)
      @@log.info 'Info-ZIP: CRC check passed'

      # Get zip file entries
      @entries = get_entries(filename)
      @@log.info 'Info-ZIP: entries parsed'
    end

    def unpack(dest)
      @@log.info "Info-ZIP: unpacking to #{dest}"
      child = POSIX::Spawn::Child.new('unzip', '-d', dest, @filename, SPAWN_CHILD_OPTS)
      raise CorruptZipFileError, "Unzip failed" if child.status.exitstatus != 0
      @@log.info "Info-ZIP: unpack succeeded"
    end

    attr_reader :entries

    def size_packed
      @packed_size ||= File.size(@filename)
    end

    private

    # @return [String] version_string whitelisted version_string found
    def get_infozip_version
      child = POSIX::Spawn::Child.new('unzip', '-v', SPAWN_CHILD_OPTS)
      parse_infozip_version_string(child.out)
    end

    # @return [String] version_string whitelisted version_string found
    def parse_infozip_version_string(stdout)
      VERSION_WHITELIST.each do |ver|
        return ver if Regexp.new('\A' + ver) =~ stdout
      end
      raise UnzipBadVersionError
    end

    # Extract the files in memory and compare the CRC of each
    # expanded file with the original file's stored CRC value.
    #
    # @TODO: test memory/cpu behavior on zip bombs
    def crc_valid?(filename)
      child = POSIX::Spawn::Child.new('unzip', '-t', filename, SPAWN_CHILD_OPTS)
      child.status.exitstatus == 0
    end

    # Get zip file entries
    #
    # @return [Array<Entry>] array of entries
    def get_entries(filename)
      child = POSIX::Spawn::Child.new('unzip', '-l', filename, SPAWN_CHILD_OPTS)
      raise CorruptZipFileError if child.status.exitstatus != 0
      parse_entries(child.out)
    end

    #@TODO: test memory/cpu behavior on zip bombs
    def parse_entries(stdout)
      lines = stdout.split("\n")
      raise UnzipParsingError, 'unzip -l output has too few lines.' \
                             if lines.size < 5
      entry_lines = lines.slice(3, lines.count - 5)
      entries = []
      entry_lines.each do |entry_line|
        if /^\s*(\d+)\s+\d+-\d+-\d+\s+\d+:\d+\s+(.+)$/ =~ entry_line
          entry_size = $1.to_i
          entry_name = $2
          if entry_name[-1, 1] == '/'
            raise UnzipParsingError, "Directory entry with non-zero size." if entry_size != 0
            entries << Entry.new(:directory, entry_name, entry_size)
          else
            entries << Entry.new(:file, entry_name, entry_size)
          end
        else
          raise UnzipParsingError, 'Bad entry line.'
        end
      end
      entries
    end
  end

  class CorruptZipFile
    def unpack(d)
      raise CorruptZipFileError
    end
    def size_packed
      raise CorruptZipFileError
    end
    def entries
      raise CorruptZipFileError
    end
  end

end
