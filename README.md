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

HTML5ZipFile::File.open('path/to/file.zip') do |f|
  # ...
end
```

### Validation

The `validate` method validates the zip file itself as well as other options:

- `:size`: maximum zip file size
- `:entry_count`: maximum number of entries (files and directories)
- `:file_count`: maximum number of files
- `:directory_count`: maximum number of directories
- `:path_length`: maximum path length in characters
- `:path_components`: maximum number of path components
- `:contains_html_file`: require or disallow HTML files to exist
- `:contains_zip_file`: require or disallow embedded zip files to exist

If any validations failed, their keys will be in `failures` and `validate` will
return false.

```ruby
HTML5ZipFile::File.open('path/to/file.zip') do |f|
  unless f.validate(:path_length => 25)
    if f.failures.include? :zip
      puts 'File is not a valid zip'
    elsif f.failures.include? :path_length
      puts 'File contains paths exceeding maximum length'
    end
  end
end
```

### Unpack & destroy

The `unpack` method unpacks the zip file contents to a new or empty directory.

The `destroy_unpacked` cleans up previously unpacked files.

```ruby
HTML5ZipFile::File.open('path/to/file.zip') do |f|
  f.unpack('data')
  f.destroy_unpacked
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/adgear/html5_zip_file.


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
