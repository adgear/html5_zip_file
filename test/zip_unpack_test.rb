require 'test_helper'

require 'tmpdir'

module ZipUnpack

  class ZipFileTest < Minitest::Test

    def setup

    end

    def f
      ZipFile.new('test/data/test-ad.zip')
    end

    def test_initialize_noncorrupt_pass
      f
    end

    def test_initialize_corrupt_fail
      assert_raises(CorruptZipFileError) do
        ZipFile.new('test/data/invalid.zip')
      end
    end

    def test_get_infozip_version_thismachine_pass
      assert_includes ZipFile::VERSION_WHITELIST, f.send(:get_infozip_version)
    end

    def test_parse_infozip_version_string_whitelisted_pass
      osx_5_52 = 'UnZip 5.52 of 28 February 2005, by Info-ZIP.  Maintained by C. Spieler.  Send\nbug reports'
      debian_6_00 = 'UnZip 6.00 of 20 April 2009, by Debian. Original by Info-ZIP.\n\nLatest sources and'
      assert_equal 'UnZip 5.52', f.send(:parse_infozip_version_string, osx_5_52)
      assert_equal 'UnZip 6.0', f.send(:parse_infozip_version_string, debian_6_00)
    end

    def test_parse_infozip_version_string_unwhitelisted_fail
      bad_version = 'UnZip 3.00 of 20 April 1945, by StrangeDistro. Original by Info-ZIP.\n\nLatest sources and.'
      assert_raises(ZipFile::UnzipBadVersionError) do
        f.send(:parse_infozip_version_string, bad_version)
      end
    end

    def test_crc_valid_noncorrupt_pass
      assert f.send(:crc_valid?, 'test/data/test-ad.zip')
    end

    def test_crc_valid_corrupt_fail
      refute f.send(:crc_valid?, 'test/data/invalid.zip')
    end

    def test_get_entries_noncorrupt_pass
      assert_equal 6, f.send(:get_entries, 'test/data/test-ad.zip').size
    end

    def test_get_entries_corrupt_fail
      assert_raises(CorruptZipFileError) do
        f.send(:get_entries, 'test/data/invalid.zip')
      end
    end

    def test_parse_entries_odd_spacing_pass
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

    def test_parse_entries_bad_stdout_fail
      stdout = <<-EOS
         Archive:  test-ad.zip
         Length      Date   Time    Name
         --------    ----   ----    ----
         --------                   -------
      EOS
      assert_raises(ZipFile::UnzipParsingError) do
        f.send(:parse_entries, stdout)
      end
    end

    def test_parse_entries_empty_zip_file_pass
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

    def test_parse_entries_nonstandard_names_pass
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

    def test_parse_entries_zero_sized_file_pass
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

    def test_parse_entries_non_zero_sized_dir_fail
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
      assert_raises(ZipFile::UnzipParsingError) do
        f.send(:parse_entries, stdout)
      end
    end

    def test_unpack
      Dir.mktmpdir do |d|
        f.unpack(d)
        assert_equal 5, Dir.new(d).entries.size
      end
    end

    def test_entries
      assert_equal 6, f.entries.size
    end

    # $ stat -f%z test/data/test-ad.zip
    # 729889
    def test_size_packed
      assert_equal 729_889, f.size_packed
    end

  end
 end
