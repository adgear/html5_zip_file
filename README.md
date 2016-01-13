# Html5ZipFile

HTML 5 zip file validation, unpacking and manipulation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html5_zip_file'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html5_zip_file

## Usage

```ruby
require 'html5_zip_file'
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
