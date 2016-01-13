require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

desc "Console"
task :console do
  require "irb"
  require 'irb/completion'

  require 'rubygems'
  require "html5_zip_file"

  ARGV.clear
  IRB.start
end

task :default => :test
