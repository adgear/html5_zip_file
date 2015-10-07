require 'test_helper'
require 'html5_zip_file/file'
require 'byebug'

module HTML5ZipFile
  class FileTest < Minitest::Test
    def test_that_it_raises_exception_when_given_invalid_zip
      assert_raises(HTML5ZipFile::InvalidZipArchive) do
        HTML5ZipFile::File.new('test/data/invalid.zip')
      end
    end

    def test_content_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      content = zip.content
      assert_equal 5, content.size
      zip.close
    end

    def test_files_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      files = zip.files
      assert_equal 3, files.size
      zip.close
    end

    def test_directories_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      directories = zip.directories
      assert_equal 2, directories.size
      zip.close
    end

    def test_files_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      files = zip.files
      assert_equal 3, files.size
      zip.close
    end

    def test_html_files_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      html_files = zip.html_files
      assert_equal 2, html_files.size
      zip.close
    end

    def test_estimated_size_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      estimated_size = zip.estimated_size
      assert_equal 732287, estimated_size
      zip.close
    end

    def test_file_size_on_valid_zip_archive
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      file_size = zip.file_size
      assert_equal 729766, file_size
      zip.close
    end

    def test_unpack_on_new_empty_folder
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      zip.unpack('test/unpack')
      entries = Dir.entries('test/unpack')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'foo', entries[2]
      assert_equal 'images', entries[3]

      entries = Dir.entries('test/unpack/foo')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'index.html', entries[2]

      entries = Dir.entries('test/unpack/images')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'test.png', entries[2]

      zip.close
      FileUtils.rm_rf(Dir.glob("test/unpack/*"))
    end

    def test_unpack_on_non_empty_folder
      assert_raises(HTML5ZipFile::DestinationIsNotEmpty) do
        zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
        zip.unpack('test/unpack_non_empty')
        zip.close
      end
    end

    def test_unpack_to_a_new_folder
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      zip.unpack('test/new_unpack')
      entries = Dir.entries('test/new_unpack')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'foo', entries[2]
      assert_equal 'images', entries[3]

      entries = Dir.entries('test/new_unpack/foo')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'index.html', entries[2]

      entries = Dir.entries('test/new_unpack/images')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]
      assert_equal 'test.png', entries[2]

      FileUtils.rm_rf("test/new_unpack")
      zip.close
    end

    def test_destroy_unpacked
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip')
      zip.unpack('test/new_unpack')
      assert Dir.exists?('test/new_unpack')
      zip.destroy_unpacked
      entries = Dir.entries('test/new_unpack')
      assert_equal '.', entries[0]
      assert_equal '..', entries[1]

      FileUtils.rm_rf("test/new_unpack")
      zip.close
    end

    def test_validate_when_archive_is_too_big
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip', {:max_size => 1})
      zip.validate
      refute zip.is_valid?
      assert_equal "The zip archive is too big.", zip.errors.first
      zip.close
    end

    def test_validate_when_archive_has_too_many_files
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip', {:max_nb_files => 1})
      zip.validate
      refute zip.is_valid?
      assert_equal "There are too many files in the zip archive.", zip.errors.first
      zip.close
    end

    def test_validate_when_archive_has_too_many_directories
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip', {:max_nb_dirs => 1})
      zip.validate
      refute zip.is_valid?
      assert_equal "There are too many directories in the zip archive.", zip.errors.first
      zip.close
    end

    def test_validate_when_archive_has_too_many_entries
      zip = HTML5ZipFile::File.new('test/data/test-ad.zip', {:max_nb_entries => 1})
      zip.validate
      refute zip.is_valid?
      assert_equal "There are too many entries in the zip archive.", zip.errors.first
      zip.close
    end
  end
end