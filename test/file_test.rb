require 'test_helper'

require 'tmpdir'

module HTML5ZipFile

  class FileTest < Minitest::Test

    def setup
      ZipUnpack::ZipFile.set_log_level Logger::FATAL
    end

    def test_validate_valid_zip
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate
        assert_empty f.failures
      end
    end

    def test_validate_invalid_zip
      File.open('test/data/invalid.zip') do |f|
        refute f.validate
        assert_equal [:zip], f.failures

        require 'tmpdir'
        Dir.mktmpdir('HTML5ZipFile_extract_TEST_UNPACK_') do |d|
          assert_nil f.unpack(d)
        end

        assert_equal f.size_packed, 0
        assert_equal f.size_unpacked, 0
        assert_equal f.entries, []
        assert_equal f.file_entries, []
        assert_equal f.directory_entries, []
        assert_equal f.html_file_entries, []
      end
    end


    def test_validate_valid_size_packed
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:size_packed => 729890)
      end
    end

    def test_validate_invalid_size_packed
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:size_packed => 729888)
        assert_equal [:size_packed], f.failures
      end
    end

    def test_validate_valid_size_unpacked
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:size_unpacked => 732275)
      end
    end

    def test_validate_invalid_size_unpacked
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:size_unpacked => 732273)
        assert_equal [:size_unpacked], f.failures
      end
    end

    def test_validate_valid_entry_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:entry_count => 6)
        assert f.validate(:entry_count => 9)
      end
    end

    def test_validate_invalid_entry_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:entry_count => 5)
        assert_equal [:entry_count], f.failures
        refute f.validate(:entry_count => 3)
      end
    end

    def test_validate_valid_file_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:file_count => 4)
      end
    end

    def test_validate_invalid_file_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:file_count => 3)
        assert_equal [:file_count], f.failures
      end
    end

    def test_validate_valid_directory_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:directory_count => 2)
      end
    end

    def test_validate_invalid_directory_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:directory_count => 1)
        assert_equal [:directory_count], f.failures
      end
    end

    def test_validate_valid_directory_count_nested_directories
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        assert f.validate(:directory_count => 2)
        assert_equal 6, f.entries.size
        assert_equal 4, f.file_entries.size
        assert_equal 2, f.directory_entries.size
      end
    end

    def test_validate_valid_path_length
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:path_length => 15)
        assert f.validate(:path_length => 25)
      end
    end

    def test_validate_invalid_path_length
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:path_length => 14)
        assert_equal [:path_length], f.failures
      end
    end

    def test_validate_valid_path_components
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        assert f.validate(:path_components => 3)
        assert f.validate(:path_components => 7)
      end
    end

    def test_validate_invalid_path_components
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        refute f.validate(:path_components => 2)
        assert_equal [:path_components], f.failures
      end
    end

    def test_validate_valid_contains_html_file
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:contains_html_file => true)
      end
      File.open('test/data/test-ad-no-html.zip') do |f|
        assert f.validate(:contains_html_file => false)
      end
    end

    def test_validate_invalid_contains_html_file
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:contains_html_file => false)
        assert_equal [:contains_html_file], f.failures
      end
      File.open('test/data/test-ad-no-html.zip') do |f|
        refute f.validate(:contains_html_file => true)
        assert_equal [:contains_html_file], f.failures
      end
    end

    def test_validate_mixed
      File.open('test/data/test-ad.zip') do |f|
        valid = f.validate(
          :size_unpacked => 1_000_000,
          :entry_count => 6,
          :file_count => 2,
          :directory_count => 2,
          :path_length => 10,
          :path_components => 5,
          :contains_html_file => true
        )
        refute valid
        assert_equal 2, f.failures.size
        assert_includes f.failures, :file_count
        assert_includes f.failures, :path_length
      end
    end

    def test_validate_invalid_zip_mixed
      File.open('test/data/invalid.zip') do |f|
        refute f.validate(:entry_count => 6, :file_count => 2)
        assert_equal [:zip], f.failures
      end
    end

    def test_unpack_bad_destinations
      File.open('test/data/test-ad.zip') do |f|
        assert_raises(InexistentError) do
          f.unpack('test/data/this/directory_does_not_exist')
        end
        assert_raises(NotEmptyError) do
          f.unpack('test/unpack_non_empty')
        end
      end
    end

    def test_unpack_good_destination
      File.open('test/data/test-ad.zip') do |f|

        Dir.mktmpdir("HTML5ZipFile_extract_TEST_UNPACK_") do |d|
          f.unpack(d)
          entries = Dir.entries(d)
          assert_equal 5, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'images'
          assert_includes entries, 'foo'

          entries = Dir.entries(d+'/images')
          assert_equal 3, entries.size
          assert_includes entries, 'test.png'

          entries = Dir.entries(d+'/foo')
          assert_equal 4, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'index2.html'
        end

      end
    end

    # $  stat -f%z test/data/test-ad.zip
    # 729889
    def test_size_packed
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 729889, f.size_packed
      end
    end

    # 112 + 62 + 41 + 732059 = 732274
    def test_size_unpacked
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 732274, f.size_unpacked
      end
    end

    def test_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 6, f.entries.size
        f.entries.each do |e|
          assert e.ftype == :file || e.ftype == :directory
        end
      end
    end

    def test_file_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 4, f.file_entries.size
        f.file_entries.each do |e|
          assert e.ftype == :file
        end
      end
    end

    def test_directory_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 2, f.directory_entries.size
        f.directory_entries.each do |e|
          assert e.ftype == :directory
          assert e.size == 0
        end
      end
    end

    def test_html_file_entries
      File.open('test/data/test-ad-mixed-case-hTmL.zip') do |f|
        assert_equal 6, f.html_file_entries.size
      end
    end

  end
end
