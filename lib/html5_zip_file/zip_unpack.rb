require 'logger'

require 'rubygems'
require 'html5_zip_file/subprocess'



# extract inside a jail
#
# test to enforce whitelisted CLI binary versions
# --> implement as a class method, called by the constructor (and a test...)
# --> hook check_infozip() into rails startup code.
#
# An alternative would be to use the Python standard library's zip module
#
# Try dropping the checks and depending instead on limits enforced by linux fs namespace / cgroups




# https://www.pkware.com/support/zip-app-note/
# https://en.wikipedia.org/wiki/Zip_(file_format)
# https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html

module ZipUnpack

  # "Unpack failed"
  Error = Class.new(StandardError)
  VersionException = Class.new(Error)
  ParsingException = Class.new(Error)
  CorruptZipFileError = Class.new(Error)

  class Entry
    attr_reader :ftype, :name, :size
    def initialize(ftype, name, size)
      @ftype = ftype
      @name = name
      @size = size
    end
  end

  # @abstract
  class ZipFile

    @@log = Logger.new(STDOUT)
    @@log.level = Logger::INFO

    def initialize
      @name = ''
      @entries = []
    end

    def size_packed
      0
    end

    attr_reader :entries

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

    # Compatible Info-ZIP versions
    VERSION_WHITELIST = ["UnZip 5.52"]#, "UnZip 6.0"]

    def initialize(name)
      super()

      @name = name

      # Check cmd line utility presence & version
      self.class.check_infozip()

      # Check zip file integrity
      self.class.check_crc(name)

      # Get zip file entries
      @entries = self.class.get_entries(name)
    end

    def size_packed
      @packed_size ||= File.size(@name)
    end

    # Warning: user-provided zip files should always be unpacked in a sandbox
    #
    # @todo test "should raise exception if results don't match manifest"
    #
    #
    def unpack(dest)
      @@log.info "Info-ZIP: unpacking #{@name} to #{dest}"
      # sandbox here.
      exit_code, stdout, stderr = Subprocess::popen('unzip', '-d', dest, @name)
      if exit_code == 0
        @@log.info "Info-ZIP: unpacked  succeeded"
        # Raise exception if result doesn't match what was in the manifest
      else
        self.class.log_debug_info(Logger::ERROR, exit_code, stdout, stderr)
        raise CorruptZipFileError, "Unzip failed (unpack#{@name} to #{dest})."
      end
      return nil
    end

    private

    def self.check_infozip()
      # raises CommandNotFoundException if the binary is not found
      exit_code, stdout, stderr = Subprocess.popen('unzip', '-v')
      VERSION_WHITELIST.each do |ver|
        if Regexp.new('\A'+ver) =~ stdout
          @@log.info "Info-ZIP: found version #{ver}"
          return
        end
      end
      log_debug_info(Logger::FATAL, exit_code, stdout, stderr)
      raise VersionException, "Version does not match whitelist #{VERSION_WHITELIST}."
    end

    # Extract the files in memory and compare the CRC of each
    # expanded file with the original file's stored CRC value.
    #
    # @TODO: test memory/cpu behavior on zip bombs
    def self.check_crc(name)
      exit_code, stdout, stderr = Subprocess::popen('unzip', '-t', name)
      if exit_code == 0
        @@log.info "Info-ZIP: CRC check passed (#{name})"
      else
        log_debug_info(Logger::ERROR, exit_code, stdout, stderr)
        raise CorruptZipFileError, "CRC check failed on #{name}"
      end
    end

    # Get zip file entries (without extracting)
    #
    # @TODO: test memory/cpu behavior on zip bombs

    def self.get_entries(name)
      exit_code, stdout, stderr = Subprocess::popen('unzip', '-l', name)
      if exit_code == 0
        entries = parse_list_stdout(stdout)
        @@log.info "Info-ZIP: entries parsed (#{name})"
        return entries
      else
        log_debug_info(exit_code, stdout, stderr)
        raise CorruptZipFileError, "Failed to get entries (#{name})"
      end
    end

    # sclaret@Simons-MBP:~/workspace/html5_zip_file$ unzip -l test/data/test-ad.zip
    # Archive:  test/data/test-ad.zip
    # Length     Date      Time    Name
    # --------   ----      ----    ----
    # 112        10-06-15 10:37    index.html
    # 0          10-06-15 10:36    images/
    # 732059     10-03-15 21:58    images/test.png
    # 0          10-08-15 13:46    foo/
    # 62         10-08-15 13:46    foo/index.html
    # 41         10-08-15 13:46    foo/index2.html
    # --------                     -------
    # 732274                       6 files
    #
    # @todo move cmd line example to comment above a unit test
    #
    # @TODO: test "empty zip file"
    # @TODO: test "space in filename"
    # @TODO: test "space at beginning/end of filename"
    # @TODO: test "non zero-sized directory entry"
    def self.parse_list_stdout(stdout)
      lines = stdout.split("\n")
      raise ParsingException, "unzip -l output has too few lines." if lines.count()< 4

      entry_lines = lines[3..lines.count()-3]

      entries = []
      entry_lines.each do |entry_line|
        # 0          10-06-15 10:36    images/
        # 732059     10-03-15 21:58    images/test.png
        if /^\s*(\d+)\s+\d{2}-\d{2}-\d{2}\s+\d{2}:\d{2}\s+(.+)$/ =~ entry_line
          entry_size = $1.to_i
          entry_name = $2
          if entry_name[-1,1] == '/'
            if entry_size != 0
              @@log.fatal entry_line
              raise ParsingException, "Directory entry with non-zero size."
            end
            entries << Entry.new(:directory, entry_name, entry_size)
          else
            entries << Entry.new(:file, entry_name, entry_size)
          end
        else
          @@log.fatal entry_line
          raise ParsingException, "Bad entry line."
        end
      end

      return entries
    end

    def self.log_debug_info(level, exit_code, stdout, stderr)
      @@log.add(level) { "Info-ZIP: exit code: #{exit_code}" }
      @@log.add(level) { "Info-ZIP: stdout:\n#{stdout}" }
      @@log.add(level) { "Info-ZIP: stderr:\n#{stderr}" }
    end

  end

end
