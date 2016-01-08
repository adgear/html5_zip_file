# Html5ZipFile

HTML 5 zip file validation and unpacking.

Project home: https://github.com/adgear/html5_zip_file

Yard docs: https://adgear.github.io/html5_zip_file/frames.html

Travis CI: https://travis-ci.org/adgear/html5_zip_file

[![Build Status](https://travis-ci.org/adgear/html5_zip_file.svg?branch=ruby-1-8-7-compat)](https://travis-ci.org/adgear/html5_zip_file)

## Install for development

Perform development with the current version of ruby (2.2.2).

    git clone git@github.com:adgear/html5_zip_file.git

Install dependencies:

    $ gem install bundler
    $ bundle install

Run tests:

    $ bundle exec rake test
    $ bundle exec ruby -I test test/file_test.rb -n /.*validate_valid_zip.*/

## Usage

Run doctests: {HTML5ZipFile::File.open},
{HTML5ZipFile::File#validate} and {HTML5ZipFile::File#unpack}.

    $ bundle exec yard doctest -v
    Run options: -v --seed 20077

    # Running:

    Failed validation checks:
    size_unpacked
    file_count
    HTML5ZipFile::File#validate#test_0001_Validate a zip file = 0.02 s = .
    entries:
    #<ZipUnpack::Entry:0x007fc209c494b0 @ftype=:file, @name="index.html", @size=112>
    #<ZipUnpack::Entry:0x007fc209c493c0 @ftype=:directory, @name="images/", @size=0>
    #<ZipUnpack::Entry:0x007fc209c492d0 @ftype=:file, @name="images/test.png", @size=732059>
    #<ZipUnpack::Entry:0x007fc209c491e0 @ftype=:directory, @name="foo/", @size=0>
    #<ZipUnpack::Entry:0x007fc209c490a0 @ftype=:file, @name="foo/index.html", @size=62>
    #<ZipUnpack::Entry:0x007fc209c48fb0 @ftype=:file, @name="foo/index2.html", @size=41>
    HTML5ZipFile::File.open#test_0001_Open a zip file = 0.03 s = .
    /var/folders/_h/d4trcrkn3mv3w307j7_w3xbh0000gn/T/HTML5ZipFile_extract_20160108-93132-xa8xu9
    .
    ..
    foo
    images
    index.html
    HTML5ZipFile::File#unpack#test_0001_Unpack a zip file = 0.04 s = .

    Finished in 0.092421s, 32.4601 runs/s, 32.4601 assertions/s.

    3 runs, 3 assertions, 0 failures, 0 errors, 0 skips

## Integrate

Add the appropriate line to your application's Gemfile:

    gem 'html5_zip_file', :git => 'git://github.com/adgear/html5_zip_file'

    gem 'html5_zip_file_1_8_7', :git => 'git://github.com/adgear/html5_zip_file'

Execute:

    $ bundle install

See {file:test/kitchen_sink.rb kitchen_sink.rb} for an example of how to actually use the code.

    $ bundle exec ruby test/kitchen_sink.rb
    I, [2016-01-08T17:42:27.565892 #93089]  INFO -- : Info-ZIP: found version UnZip 5.52
    I, [2016-01-08T17:42:27.574506 #93089]  INFO -- : Info-ZIP: CRC check passed
    I, [2016-01-08T17:42:27.578093 #93089]  INFO -- : Info-ZIP: entries parsed
    size_unpacked: 732274
    #<ZipUnpack::Entry:0x007f93141a29e0 @ftype=:file, @name="index.html", @size=112>
    #<ZipUnpack::Entry:0x007f93141a2800 @ftype=:directory, @name="images/", @size=0>
    #<ZipUnpack::Entry:0x007f93141a2670 @ftype=:file, @name="images/test.png", @size=732059>
    #<ZipUnpack::Entry:0x007f93141a2468 @ftype=:directory, @name="foo/", @size=0>
    #<ZipUnpack::Entry:0x007f93141a2378 @ftype=:file, @name="foo/index.html", @size=62>
    #<ZipUnpack::Entry:0x007f93141a2210 @ftype=:file, @name="foo/index2.html", @size=41>
    Failed validation checks:
    size_unpacked
    file_count
    path_length
    contains_html_file

## Docs / Doctests

Use current ruby.

http://yardoc.org

    $ bundle exec yard help

    $ bundle exec yard doc

    $ bundle exec yard server --reload

    $ bundle exec yard list --query '@todo'

    $ bundle exec yard graph --full --dependencies | dot -Tpng -o outfile.png

https://github.com/p0deje/yard-doctest

    $ bundle exec yard config load_plugins true

    $ bundle exec yard config -a autoload_plugins yard-doctest

    $ bundle exec yard doctest -h

    $ bundle exec yard doctest -v

## External Dependency

This gem has one external dependency: the command line program 'unzip'.

http://www.info-zip.org/UnZip.html

The test suite guarantees compabitibility with unzip v5.52 & v6.0.

Versions currently provided by various distributions (2015-12-21):

- OSX: 5.52 (2005)
- Arch: 6.0-11 (4 fixes in 2015)
- Gentoo: 6.0-r3 (1 change in 2015)
- Debian: 6.0-16 (4 fixes in 2015)
- Centos: 6.0-15

If you use html5_zip_file in an application, you should run the test
suite on a production machine, and "freeze" the unzip version in the
OS's package manager.

Any time the package manager wants to update unzip, "rake test" should
be run and the gem updated as necessary.

## Security

A first layer of security is provided by imposing sensible limits on
:size_unpacked, :entry_count, :path_length and :path components via
{HTML5ZipFile::File#validate}.

### Zip entry metadata

Validation requires running the "unzip -t" and "unzip -l" commands
in subprocesses, and parsing the stdout in a ruby parent process.

### Zip unpacking

Currently, the file is unpacked to a target directory with 'unzip -d'.

We rely on unzip's internal checks to prevent unpacking of files to
locations outside the target directory.

Stronger guarantees could be provided by unpacking in a sandbox:

- Create a temporary sandbox directory with Ruby's tmpdir module.

- Rename the zip file and copy into the sandbox.

- Child process (without the ability to write to filesystem locations
  outside the sandbox) runs 'unzip -d' to a subdirectory in the
  sandbox.

- Once the child terminates, the parent copies the extracted files
  from the sandbox to their final location.

- Parent destroys the sandbox.

Steps to increase the security of the sandbox:

1.) Mount the temporary filesystem on a separate partition.

Determine the location tmpdir uses through irb:

Ruby 2.2.2 on OSX:

    $ irb
    > require 'tmpdir'
    > Dir.mktmpdir do |d|
    puts d.inspect()
    > end
    "/var/folders/_h/d4trcrkn3mv3w307j7_w3xbh0000gn/T/d20151223-49143-1mxf2k4"

Ruby 2.2.2 on debian: "/tmp/d20151223-28897-7wfgjm"

2.) Use linux namespaces to prevent filesystem access outside the
sandbox by the subprocess.

3.) Drop unneeded capabilities and put resource utilization limits on
the subprocess.

## Gems

Separate gemspecs are maintained for 'current' ruby and ruby 1.8.7.

Current ruby has rubygems built-in.

    $ chruby 2.2.2

    $ gem build html5_zip_file.gemspec
    Successfully built RubyGem
    Name: html5_zip_file
    Version: 1.0
    File: html5_zip_file-1.0.gem

    $ gem install [--dev] html5_zip_file-1.0.gem
    Successfully installed html5_zip_file-1.0
    Parsing documentation for html5_zip_file-1.0
    Installing ri documentation for html5_zip_file-1.0
    Done installing documentation for html5_zip_file after 0 seconds

    $ gem which html5_zip_file
    /Users/MYUSER/.gem/ruby/2.2.2/gems/html5_zip_file-1.0/lib/html5_zip_file.rb

    $ irb
    irb(main):001:0> require 'html5_zip_file'

Ruby 1.8.7 does not have rubygems built-in: install rubygems 1.3.6
manually.

    $ chruby 1.8.7

    $ gem --version
    1.3.6

    $ gem build html5_zip_file_1_8_7.gemspec
    Successfully built RubyGem
    Name: html5_zip_file_1_8_7
    Version: 1.0
    File: html5_zip_file_1_8_7-1.0.gem

    $ gem install [--dev] html5_zip_file_1_8_7-1.0.gem
    Successfully installed html5_zip_file_1_8_7-1.0
    1 gem installed
    Installing ri documentation for html5_zip_file_1_8_7-1.0...
    Installing RDoc documentation for html5_zip_file_1_8_7-1.0...

    $ gem which html5_zip_file
    /Users/MYUSER/.gem/ruby/1.8.7/gems/html5_zip_file_1_8_7-1.0/lib/html5_zip_file.rb

    $ irb
    irb(main):001:0> require 'rubygems'
    irb(main):002:0> require 'html5_zip_file'
    irb(main):003:0> HTML5ZipFile::File
    => HTML5ZipFile::File

Note: if "gem install --dev" deadlocks, just install without --dev and
"gem install X" the development gems manually.

In theory, you could build gems, push them to a repository such as
rubygems.org, and install them in your destination environment with
"gem install XXX".

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/adgear/html5_zip_file.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
