require 'test_helper'

class SubprocessTest < Minitest::Test

  def setup

  end

  def test_inexistent_command
    assert_raises Subprocess::CommandNotFoundError do
      exit_code, stdout, stderr = Subprocess.popen('unzipFAIL', '-v')
    end
  end

end
