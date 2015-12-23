# Uniform interface for safely executing a child process, that works
# identically under ruby 1.8.7 and ruby 2.2.3.
#
# == Use Case
#
# Need a subprocess execution method that:
#
# 1.) is safe (correctly escapes parameters, does not deadlock and
#     correctly handles all subprocess termination scenarios)
# 2.) supports capturing stdout and exit codes
# 3.) works under ruby 1.8.7 and ruby 2.2.3
#
# Any method that requires the command to be passed through a shell
# does not meet criteria 1a.
#
# Options in Ruby 2.2.3:
#
# - IO::popen()
# - Kernel::system(..., :out -> ...)
# - Open3::popen3()
# - IO::pipe()/Kernel::fork()/Kernel::exec()
# - posix_spawn gem
#
# Options in Ruby 1.8.7
#
# ! IO::popen() no parameter escaping
# ! Kernel::system() cannot manipulate file descriptors
# ! Open3::popen3() no way to obtain exit code
# - IO::pipe()/Kernel::fork()/Kernel::exec()
# - posix_spawn gem
#
# Care must be taken to avoid deadlocks involving blocking reads and
# empty/overflowing pipes.
#
# Specifically, we need to clear all the output pipes without putting
# a dependency between clearing a pipe and waiting for another pipe.
#
# http://rxr.whitequark.org/mri/source/lib/open3.rb?v=1.8.7-p374
# http://rxr.whitequark.org/mri/source/lib/open3.rb?v=2.2.3
#
# http://coldattic.info/shvedsky/pro/blogs/a-foo-walks-into-a-bar/posts/60
# http://coldattic.info/shvedsky/pro/blogs/a-foo-walks-into-a-bar/posts/62
# http://coldattic.info/shvedsky/pro/blogs/a-foo-walks-into-a-bar/posts/63
# http://illuminatedcomputing.com/posts/2011/10/piping-in-ruby-with-popen3/
#
# === TODO
#
# popen() should raise an exception if the child doesn't terminate
# successfully, rather than returning incomplete or corrupt data.

class Subprocess

  SubprocessError = Class.new(StandardError)

  CommandNotFoundException = Class.new(SubprocessError)

  Timeout = Class.new(SubprocessError)
  AbnormalTermination = Class.new(SubprocessError)

  SecurityLimitBreachedException = Class.new(SubprocessError)

  SUBPROCESS_TIMEOUT = 20 #seconds
  READ_CHUNK_SIZE = 100 #bytes

  # Maximum number of 100-byte chunks to read from a file descriptor
  # before raising SecurityLimitBreachedException
  MAX_CHUNKS = 1000

  def self.popen(*args)
    raise ArgumentError if args.class != Array || args.length < 2

    stdin = IO::pipe #Pipe[0] for read, pipe[1] for write
    stdout = IO::pipe
    stderr = IO::pipe

    child_pid = fork

    if child_pid.nil?

      # in the child

      stdin[1].close
      STDIN.reopen(stdin[0])
      stdin[0].close

      stdout[0].close
      STDOUT.reopen(stdout[1])
      stdout[1].close

      stderr[0].close
      STDERR.reopen(stderr[1])
      stderr[1].close

      begin
        exec(*args)
      rescue Errno::ENOENT => e
        # cannot simply re-raise an exception because it won't
        # reliable reach the parent process
        exit(240)
        # @TODO, find a better way to propagate ENOENT to the parent
      end

    else

      # in the parent

      stdin[0].close
      stdout[1].close
      stderr[1].close

      stdin[1].close

      stdout_contents, stderr_contents = collect_data(stdout[0], stderr[0])

      Process.wait(child_pid)

      stdout[0].close
      stderr[0].close

      exit_code = $?.exitstatus
      if exit_code == 240
        raise CommandNotFoundException, "Could not find the command #{args[0]}"
      end

      return exit_code, stdout_contents, stderr_contents
      # in the parent


    end
  end

  def self.collect_data(stdout, stderr)
    o_chunks_read, e_chunks_read = 0, 0

    open_fds = [stdout, stderr]
    stdout_content, stderr_content = '', ''
    while !open_fds.empty?
      ready_fds = select(open_fds, nil, nil, SUBPROCESS_TIMEOUT)
      raise Timeout if ready_fds.nil?
      if ready_fds[0].include?(stdout)
        begin
          o_chunks_read += 1
          raise SecurityLimitBreachedException if o_chunks_read > MAX_CHUNKS
          stdout_content << stdout.read_nonblock(READ_CHUNK_SIZE)
        rescue EOFError
          open_fds.delete_if{ |f| f == stdout}
        end
      end
      if ready_fds[0].include?(stderr)
        begin
          e_chunks_read += 1
          raise SecurityLimitBreachedException if e_chunks_read > MAX_CHUNKS
          stderr_content << stderr.read_nonblock(READ_CHUNK_SIZE)
        rescue EOFError
          open_fds.delete_if{ |f| f == stderr}
        end
      end
    end
    return stdout_content, stderr_content
  end

end










# exit_code, stdout, stderr = Subprocess.popen('unzip', '-v')
# puts "exit code: #{exit_code}"
# puts "stdout:\n#{stdout}"
# puts "stderr:\n#{stderr}"

# puts '-----'

# exit_code, stdout, stderr = Subprocess.popen('unzip', '-t', 'test/data/invalid.zip')
# puts "exit code: #{exit_code}"
# puts "stdout:\n#{stdout}"
# puts "stderr:\n#{stderr}"

# puts '-----'

# exit_code, stdout, stderr = Subprocess.popen('unzip', '-t', 'test/data/test-ad.zip')
# puts "exit code: #{exit_code}"
# puts "stdout:\n#{stdout}"
# puts "stderr:\n#{stderr}"

# puts '-----'

# exit_code, stdout, stderr = Subprocess.popen('unzip', '-l', 'test/data/test-ad.zip')
# puts "exit code: #{exit_code}"
# puts "stdout:\n#{stdout}"
# puts "stderr:\n#{stderr}"




# puts "Non-zero exit code:\n"
# exit_code, stdout, stderr = Subprocess.popen('wget', 'https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.3.tar.xzFAIL')
# puts "exit code: #{exit_code}"
# puts "stdout: #{stdout}"
# puts "stderr: #{stderr}"

# puts "Zero exit code:\n"
# exit_code, stdout, stderr = Subprocess.popen('wget', 'https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.3.tar.xz')
# puts "exit code: #{exit_code}"
# puts "stdout: #{stdout}"
# puts "stderr: #{stderr}"

# def self.popen(*args)

#   raise ArgumentError if args.class != Array || args.length < 2

#   stdin, stdout, stderr = Open3.popen3(*args)
#   stdin.close()
#   open_fds = [stdout, stderr]

#   stdout_content, stderr_content = '', ''

#   while !open_fds.empty?
#     ready_fds = select(open_fds, nil, nil, SUBPROCESS_TIMEOUT)
#     raise Timeout if ready_fds.nil?
#     if ready_fds[0].include?(stdout)
#       begin
#         stdout_content << stdout.read_nonblock(READ_CHUNK_SIZE)
#       rescue EOFError
#         open_fds.delete_if{ |f| f == stdout}
#       end
#     end
#     if ready_fds[0].include?(stderr)
#       begin
#         stderr_content << stderr.read_nonblock(READ_CHUNK_SIZE)
#       rescue EOFError
#         open_fds.delete_if{ |f| f == stderr}
#       end
#     end
#   end

#   exit_code = 999

#   return exit_code, stdout_content, stderr_content
# end
