require 'test_helper'

class HTML5ZipFileTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HTML5ZipFile::VERSION
  end
end
