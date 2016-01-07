require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
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
