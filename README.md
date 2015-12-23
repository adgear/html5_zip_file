# Html5ZipFile

HTML 5 zip file validation and unpacking.

Project home: https://github.com/adgear/html5_zip_file

Yard docs: https://adgear.github.io/html5_zip_file/frames.html

Travis CI: https://travis-ci.org/adgear/html5_zip_file

[![Build Status](https://travis-ci.org/adgear/html5_zip_file.svg?branch=ruby-1-8-7-compat)](https://travis-ci.org/adgear/html5_zip_file)


## Install for development

Perform development with the current version of ruby (2.2.2).

Check out the code:

    git clone git@github.com:adgear/html5_zip_file.git

Install dependencies directly (without building a gem):

    $ gem install bundler
    $ bundle install

Run tests:

    $ bundle exec rake test
    $ bundle exec ruby -I test test/file_test.rb -n /.*validate_valid_zip.*/

Experiment with the console:

    $ mkdir /tmp/test_extract
    $ bundle exec rake console
    irb(main):001:0> HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|
    irb(main):002:1*
    irb(main):003:1* file_valid = f.validate( :unpacked_size => 700000 )
    irb(main):004:1>
    irb(main):005:1*   if file_valid
    irb(main):006:2>     f.unpack('/tmp/test_extract')
    irb(main):007:2>   else
    irb(main):008:2*     f.failures.each { |failure|  puts(failure) }
    irb(main):009:2>   end
    irb(main):010:1>
    irb(main):011:1* end

    I, [2015-12-23T17:01:14.788303 #72989]  INFO -- : Info-ZIP: found version UnZip 5.52
    I, [2015-12-23T17:01:14.802631 #72989]  INFO -- : Info-ZIP: CRC check passed
    I, [2015-12-23T17:01:14.808715 #72989]  INFO -- : Info-ZIP: entries parsed
    I, [2015-12-23T17:01:14.808924 #72989]  INFO -- : Info-ZIP: unpacking to /tmp/test_extract5
    I, [2015-12-23T17:01:14.825811 #72989]  INFO -- : Info-ZIP: unpacked succeeded

While developing, you could add testing code at the bottom of a file and run it:

    $ bundle exec ruby lib/html5_zip_file/file.rb

But try writing a doctest directly as a comment of the class/method, and executing it:

    $ bundle exec yard doctest lib/html5_zip_file/file.rb

This is an easy way to produce documentation. See [Docs / Doctests](#label-Docs+-2F+Doctests) for details.

To run the test suite on ruby 1.8.7, build the html5_zip_file_1_8_7
gem, install it under ruby 1.8.7 and run 'rake test'.


## Install into an application

Add the appropriate line to your application's Gemfile:

    gem 'html5_zip_file', :git => 'git://github.com/adgear/html5_zip_file'

    gem 'html5_zip_file_1_8_7', :git => 'git://github.com/adgear/html5_zip_file'

Execute:

    $ bundle install

Integrate into your application:

    require 'html5_zip_file'

    HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|
      ...
    end


## Usage

For a more sophisticated example, examine the doctest of
{HTML5ZipFile::File.open}, then run it:

    $ bundle exec yard doctest
    Run options: --seed 27241

    # Running:

    I, [2015-12-23T17:02:57.023388 #73007]  INFO -- : Info-ZIP: found version UnZip 5.52
    I, [2015-12-23T17:02:57.032418 #73007]  INFO -- : Info-ZIP: CRC check passed
    I, [2015-12-23T17:02:57.036838 #73007]  INFO -- : Info-ZIP: entries parsed

    size_unpacked:
    732274

    entries:
    #<ZipUnpack::Entry:0x007fd6f3874188 @ftype=:file, @name="index.html", @size=112>
    #<ZipUnpack::Entry:0x007fd6f386fea8 @ftype=:directory, @name="images/", @size=0>
    #<ZipUnpack::Entry:0x007fd6f386f980 @ftype=:file, @name="images/test.png", @size=732059>
    #<ZipUnpack::Entry:0x007fd6f386f750 @ftype=:directory, @name="foo/", @size=0>
    #<ZipUnpack::Entry:0x007fd6f386f480 @ftype=:file, @name="foo/index.html", @size=62>
    #<ZipUnpack::Entry:0x007fd6f386f048 @ftype=:file, @name="foo/index2.html", @size=41>

    Failed validation checks:
    size_unpacked
    file_count
    path_length
    contains_html_file
    .

    Finished in 0.025196s, 39.6888 runs/s, 39.6888 assertions/s.

    1 runs, 1 assertions, 0 failures, 0 errors, 0 skips

Try editing the doctest.

Change the validation criteria in lib/html5_zip_file/file.rb:

    :size_unpacked => 740000, :file_count => 6, :path_length => 15, :contains_html_file => true

And re-run it:

    $ bundle exec yard doctest lib/html5_zip_file/file.rb

Also, try changing file_name from 'test-ad.zip' to 'invalid.zip'.

### Validate

See {HTML5ZipFile::File#validate}.


### Unpack

See {HTML5ZipFile::File#unpack}.


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


## Docs / Doctests

Note: the following don't work under ruby 1.8.7.  Use current ruby if
you want to regenerate the documentation and run the doctests.

http://yardoc.org

https://github.com/p0deje/yard-doctest

    build doc/

    $ bundle exec yard doc

    live preview:

    $ bundle exec yard server --reload

    filter:

    $ bundle exec yard list --query '@todo'

    graph:

    $ bundle exec yard graph --full --dependencies | dot -Tpng -o outfile.png

    $ bundle exec yard --help

    $ bundle exec yard config load_plugins true

    $ bundle exec yard config -a autoload_plugins yard-doctest

    $ bundle exec yard doctest


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

A limit of 100 kilobytes is placed on the output of the subprocess, to
limit the damage a runaway (possibly malicious) subprocess can do to
its parent. See Subprocess::MAX_CHUNKS.


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

Several steps can be taken to increase the security of the sandbox:

1.) Mount the temporary filesystem on a separate partition.

You can determine what location tmpdir uses through irb:

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


## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/adgear/html5_zip_file.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
