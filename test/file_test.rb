require 'test_helper'

require 'tmpdir'

module HTML5ZipFile

  class FileTest < Minitest::Test

    def test_validate_noncorrupt_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate
        assert_empty f.failures
      end
    end

    def test_validate_corrupt_fail
      File.open('test/data/invalid.zip') do |f|
        refute f.validate(:entries => 6, :file_entries => 2)
        assert_equal [:zip], f.failures

        Dir.mktmpdir("HTML5ZipFile_extract_TEST_UNPACK_") do |d|
          assert_raises(ZipUnpack::CorruptZipFileError) { f.unpack(d) }
        end

        assert_raises(ZipUnpack::CorruptZipFileError) { f.size_packed }
        assert_raises(ZipUnpack::CorruptZipFileError) { f.size_unpacked }
        assert_raises(ZipUnpack::CorruptZipFileError) { f.entries }
        assert_raises(ZipUnpack::CorruptZipFileError) { f.file_entries }
        assert_raises(ZipUnpack::CorruptZipFileError) { f.directory_entries }
        assert_raises(ZipUnpack::CorruptZipFileError) { f.html_file_entries }
      end
    end

    def test_validate_size_packed_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:size_packed => 729890)
      end
    end

    def test_validate_size_packed_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:size_packed => 729888)
        assert_equal [:size_packed], f.failures
      end
    end

    def test_validate_size_unpacked_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:size_unpacked => 732275)
      end
    end

    def test_validate_size_unpacked_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:size_unpacked => 732273)
        assert_equal [:size_unpacked], f.failures
      end
    end

    def test_validate_entries_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:entries => 6)
        assert f.validate(:entries => 9)
      end
    end

    def test_validate_entries_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:entries => 5)
        assert_equal [:entries], f.failures
        refute f.validate(:entries => 3)
      end
    end

    def test_validate_file_entries_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:file_entries => 4)
      end
    end

    def test_validate_file_entries_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:file_entries => 3)
        assert_equal [:file_entries], f.failures
      end
    end

    def test_validate_directory_entries_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:directory_entries => 2)
      end
    end

    def test_validate_directory_entries_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:directory_entries => 1)
        assert_equal [:directory_entries], f.failures
      end
    end

    def test_validate_directory_entries_nested
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        assert f.validate(:directory_entries => 2)
        assert_equal 6, f.entries.size
        assert_equal 4, f.file_entries.size
        assert_equal 2, f.directory_entries.size
      end
    end

    def test_validate_path_length_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:path_length => 15)
        assert f.validate(:path_length => 25)
      end
    end

    def test_validate_path_length_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:path_length => 14)
        assert_equal [:path_length], f.failures
      end
    end

    def test_validate_path_components_compliant_pass
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        assert f.validate(:path_components => 3)
        assert f.validate(:path_components => 7)
      end
    end

    def test_validate_path_components_noncompliant_fail
      File.open('test/data/test-ad-nested-directories.zip') do |f|
        refute f.validate(:path_components => 2)
        assert_equal [:path_components], f.failures
      end
    end

    def test_validate_contains_html_file_compliant_pass
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(:contains_html_file => true)
      end
      File.open('test/data/test-ad-no-html.zip') do |f|
        assert f.validate(:contains_html_file => false)
      end
    end

    def test_validate_contains_html_file_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(:contains_html_file => false)
        assert_equal [:contains_html_file], f.failures
      end
      File.open('test/data/test-ad-no-html.zip') do |f|
        refute f.validate(:contains_html_file => true)
        assert_equal [:contains_html_file], f.failures
      end
    end

    def test_validate_mixed_noncompliant_fail
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(
          :size_unpacked => 1_000_000,
          :entries => 6,
          :file_entries => 2,
          :directory_entries => 2,
          :path_length => 10,
          :path_components => 5,
          :contains_html_file => true
        )
        assert_equal 2, f.failures.size
        assert_includes f.failures, :file_entries
        assert_includes f.failures, :path_length
      end
    end

    def test_unpack_good_destination_pass
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

    def test_unpack_bad_destination_fail
      File.open('test/data/test-ad.zip') do |f|
        assert_raises(InexistentError) do
          f.unpack('test/data/this/directory_does_not_exist')
        end
        assert_raises(NotEmptyError) do
          f.unpack('test/unpack_non_empty')
        end
      end
    end

    # $  stat -f%z test/data/test-ad.zip
    # 729889
    def test_size_packed_test_ad
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 729889, f.size_packed
      end
    end

    # 112 + 62 + 41 + 732059 = 732274
    def test_size_unpacked_test_ad
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 732274, f.size_unpacked
      end
    end

    def test_entries_test_ad
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 6, f.entries.size
        f.entries.each do |e|
          assert e.ftype == :file || e.ftype == :directory
        end
      end
    end

    def test_file_entries_test_ad
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 4, f.file_entries.size
        f.file_entries.each do |e|
          assert e.ftype == :file
        end
      end
    end

    def test_directory_entries_test_ad
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 2, f.directory_entries.size
        f.directory_entries.each do |e|
          assert e.ftype == :directory
          assert e.size == 0
        end
      end
    end

    def test_html_file_entries_test_ad_mixed_case_hTml
      File.open('test/data/test-ad-mixed-case-hTmL.zip') do |f|
        assert_equal 6, f.html_file_entries.size
      end
    end

  end
end
