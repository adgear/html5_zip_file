require 'test_helper'
require 'html5_zip_file/file'
require 'byebug'

module HTML5ZipFile
  class FileTest < Minitest::Test
    def test_validate_valid_zip
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate
      end
    end

    def test_validate_invalid_zip
      File.open('test/data/invalid.zip') do |f|
        refute f.validate
        assert_equal [:zip], f.failures
      end
    end

    def test_validate_valid_contents__size
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(contents_size: 20_000_000)
      end
    end

    def test_validate_invalid_contents_size
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(contents_size: 100_000)
        assert_equal [:contents_size], f.failures
      end
    end

    def test_validate_valid_entry_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(entry_count: 6)
      end
    end

    def test_validate_invalid_entry_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(entry_count: 5)
        assert_equal [:entry_count], f.failures
      end
    end

    def test_validate_valid_file_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(file_count: 4)
      end
    end

    def test_validate_invalid_file_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(file_count: 3)
        assert_equal [:file_count], f.failures
      end
    end

    def test_validate_valid_directory_count
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(directory_count: 2)
      end
    end

    def test_validate_invalid_directory_count
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(directory_count: 1)
        assert_equal [:directory_count], f.failures
      end
    end

    def test_validate_valid_path_length
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(path_length: 15)
      end
    end

    def test_validate_invalid_path_length
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(path_length: 14)
        assert_equal [:path_length], f.failures
      end
    end

    def test_validate_valid_path_components
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(path_components: 2)
      end
    end

    def test_validate_invalid_path_components
      File.open('test/data/test-ad.zip') do |f|
        refute f.validate(path_components: 1)
        assert_equal [:path_components], f.failures
      end
    end

    def test_validate_valid_contains_html_file
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(contains_html_file: true)
      end
    end

    def test_validate_invalid_contains_html_file
      File.open('test/data/test-ad-no-html.zip') do |f|
        refute f.validate(contains_html_file: true)
        assert_equal [:contains_html_file], f.failures
      end
    end

    def test_validate_valid_contains_zip_file
      File.open('test/data/test-ad.zip') do |f|
        assert f.validate(contains_zip_file: false)
      end
    end

    def test_validate_invalid_contains_zip_file
      File.open('test/data/test-ad-with-zip.zip') do |f|
        refute f.validate(contains_zip_file: false)
        assert_equal [:contains_zip_file], f.failures
      end
    end

    def test_validate_mixed
      File.open('test/data/test-ad.zip') do |f|
        valid = f.validate(
          size: 1_000_000,
          entry_count: 6,
          file_count: 2,
          directory_count: 2,
          path_length: 10,
          path_components: 5,
          contains_html_file: true,
          contains_zip_file: false
        )
        refute valid
        assert_equal 2, f.failures.size
        assert_includes f.failures, :file_count
        assert_includes f.failures, :path_length
      end
    end

    def test_validate_invalid_zip_mixed
      File.open('test/data/invalid.zip') do |f|
        refute f.validate(entry_count: 6, file_count: 2)
        assert_equal [:zip], f.failures
      end
    end

    def test_validate_forbidden_characters
      File.open('test/data/test-ad-with-spaces.zip') do |f|
        refute f.validate(forbidden_characters: / /)
        assert_equal [:forbidden_characters], f.failures
      end
    end

    def test_validate_forbidden_characters_only_in_filenames
      File.open('test/data/test-ad-with-spaces.zip') do |f|
        assert f.validate(forbidden_characters: %r{/})
      end
    end

    def test_contents_size
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 732_274, f.contents_size
      end
    end

    def test_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 6, f.entries.size
      end
    end

    def test_file_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 4, f.file_entries.size
      end
    end

    def test_directory_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 2, f.directory_entries.size
      end
    end

    def test_html_file_entries
      File.open('test/data/test-ad.zip') do |f|
        assert_equal 3, f.html_file_entries.size
      end
    end

    class Unpack < Minitest::Test
      def teardown
        FileUtils.rm_rf('test/unpack')
      end

      def test_unpack_non_empty
        assert_raises(DestinationNotEmpty) do
          File.open('test/data/test-ad.zip') do |f|
            f.unpack('test/unpack_non_empty')
          end
        end
      end

      def test_unpack_empty
        FileUtils.mkdir_p('test/unpack')

        File.open('test/data/test-ad.zip') do |f|
          f.unpack('test/unpack')

          entries = Dir.entries('test/unpack')
          assert_equal 5, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'images'
          assert_includes entries, 'foo'

          entries = Dir.entries('test/unpack/images')
          assert_equal 3, entries.size
          assert_includes entries, 'test.png'

          entries = Dir.entries('test/unpack/foo')
          assert_equal 4, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'index2.html'
        end
      end

      def test_unpack_mkdir
        File.open('test/data/test-ad.zip') do |f|
          f.unpack('test/unpack')

          entries = Dir.entries('test/unpack')
          assert_equal 5, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'images'
          assert_includes entries, 'foo'

          entries = Dir.entries('test/unpack/images')
          assert_equal 3, entries.size
          assert_includes entries, 'test.png'

          entries = Dir.entries('test/unpack/foo')
          assert_equal 4, entries.size
          assert_includes entries, 'index.html'
          assert_includes entries, 'index2.html'
        end
      end

      def test_destroy_unpacked
        File.open('test/data/test-ad.zip') do |f|
          f.unpack('test/unpack')
          f.destroy_unpacked

          refute Dir.exist?('test/unpack')
        end
      end

      def test_inject_script_tag_not_unpacked
        assert_raises(NotUnpacked) do
          File.open('test/data/test-ad.zip') do |f|
            f.inject_script_tag('<script></script>')
          end
        end
      end

      def test_inject_script_tag_invalid
        assert_raises(InvalidScriptTag) do
          File.open('test/data/test-ad.zip') do |f|
            f.unpack('test/unpack')
            f.inject_script_tag('<div></div>')
          end
        end
      end

      def test_inject_script_tag
        File.open('test/data/test-ad.zip') do |f|
          f.unpack('test/unpack')
          f.inject_script_tag('<script src="test.js"></script>')

          data = ::File.read('test/unpack/index.html')
          assert data.start_with?('<!DOCTYPE html>')
          html = Nokogiri::HTML.parse(data)
          assert html.at_css('head script[src="test.js"]')

          data = ::File.read('test/unpack/foo/index.html')
          assert data.start_with?('<!DOCTYPE html>')
          html = Nokogiri::HTML.parse(data)
          assert html.at_css('html script[src="test.js"]')

          data = ::File.read('test/unpack/foo/index2.html')
          assert data.start_with?('<!DOCTYPE html>')
          html = Nokogiri::HTML.parse(data)
          assert html.at_css('script[src="test.js"]')
        end
      end

      def test_inject_script_tag_replace
        File.open('test/data/test-ad.zip') do |f|
          f.unpack('test/unpack')
          f.inject_script_tag('<script src="a.js"></script>')
          f.inject_script_tag('<script src="b.js"></script>')

          data = ::File.read('test/unpack/index.html')
          html = Nokogiri::HTML.parse(data)

          assert html.at_css('script[src="b.js"]')
          refute html.at_css('script[src="a.js"]')
        end
      end
    end
  end
end
