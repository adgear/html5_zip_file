require 'test_helper'

require 'tmpdir'

module ZipUnpack

  class InfoZipFileTest < Minitest::Test

    def setup
      ZipUnpack::ZipFile.set_log_level Logger::FATAL
    end

    def f
      InfoZipFile.new('test/data/test-ad.zip')
    end

    # $ stat -f%z test/data/test-ad.zip
    # 729889
    def test_size_packed
      assert_equal 729_889, f.size_packed
    end

    def test_unpack
      Dir.mktmpdir do |d|
        f.unpack(d)
        assert_equal 5, Dir.new(d).entries.size
      end
    end

    def test_get_infozip_version
      assert_includes InfoZipFile::VERSION_WHITELIST, f.send(:get_infozip_version)
    end

    def test_parse_infozip_version
      osx_5_52 = 'UnZip 5.52 of 28 February 2005, by Info-ZIP.  Maintained by C. Spieler.  Send\nbug reports'
      debian_6_00 = 'UnZip 6.00 of 20 April 2009, by Debian. Original by Info-ZIP.\n\nLatest sources and'
      bad_version = 'UnZip 3.00 of 20 April 1945, by StrangeDistro. Original by Info-ZIP.\n\nLatest sources and.'

      assert_equal 'UnZip 5.52', f.send(:parse_infozip_version, osx_5_52)
      assert_equal 'UnZip 6.0', f.send(:parse_infozip_version, debian_6_00)
      assert_equal false, f.send(:parse_infozip_version, bad_version)
    end

    def test_crc_valid?
      assert f.send(:crc_valid?, 'test/data/test-ad.zip')
      refute f.send(:crc_valid?, 'test/data/invalid.zip')
    end

    def test_get_entries
      assert_equal false, f.send(:get_entries, 'test/data/invalid.zip')
      assert_equal 6, f.send(:get_entries, 'test/data/test-ad.zip').size
    end

    def test_parse_entries
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
              112  10-06-15 10:37   index.html
                0  10-06-15 10:36   images/
           732059  10-03-15 21:58   images/test.png
0  10-08-15 13:46   foo/
62  10-08-15 13:46   foo/index.html
               41  10-08-15 13:46   foo/index2.html
         --------                   -------
           732274                   6 files
      EOS
      entries = f.send(:parse_entries, stdout).sort
      assert_equal 6, entries.size
      assert_equal entries[4].name,'images/test.png'
    end

    def test_parse_entries_bad_stdout
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
         --------                   -------
      EOS
      assert_raises(InfoZipFile::ParsingError) do
        f.send(:parse_entries, stdout)
      end
    end

    def test_parse_entries_empty_zip_file
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
         --------                   -------
                0                   0 files
      EOS
      entries = f.send(:parse_entries, stdout).sort
      assert_equal 0, entries.size
    end

    def test_parse_entries_nonstandard_names
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
              112  10-06-15 10:37   index page.html
                0  10-06-15 10:36   images/
           732059  10-03-15 21:58   images/my beach vacation.png
                0  10-08-15 13:46   foo/
               62  10-08-15 13:46   foo/price in $ of ads.json
               41  10-08-15 13:46   foo/welcome!_to_disney.html
               20  10-08-15 13:46   foo/file_without_extension
               20  10-08-15 13:46   foo/ file_with_leading_space.txt
         --------                   -------
           732294                   6 files
      EOS
      entries = f.send(:parse_entries, stdout).sort

      assert_equal 'foo/ file_with_leading_space.txt', entries[1].name
      assert_equal 'foo/file_without_extension', entries[2].name
      assert_equal 'foo/price in $ of ads.json', entries[3].name
      assert_equal 'foo/welcome!_to_disney.html', entries[4].name

      assert_equal 'images/my beach vacation.png', entries[6].name
      assert_equal 'index page.html', entries[7].name
    end

    def test_parse_entries_zero_sized_file
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
                0  10-06-15 10:37   index.html
                0  10-06-15 10:36   images/
           732059  10-03-15 21:58   images/test.png
         --------                   -------
          9999999                   6 files
      EOS
      entries = f.send(:parse_entries, stdout).sort

      assert_equal :file, entries[2].ftype
      assert_equal 'index.html', entries[2].name
      assert_equal 0, entries[2].size
    end

    def test_parse_entries_non_zero_sized_dir
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
              112  10-06-15 10:37   index.html
               10  10-06-15 10:36   images/
           732059  10-03-15 21:58   images/test.png
         --------                   -------
          9999999                   6 files
      EOS
      assert_raises(InfoZipFile::ParsingError) do
        f.send(:parse_entries, stdout)
      end
    end

  end
 end
