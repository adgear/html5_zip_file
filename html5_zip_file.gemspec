lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'html5_zip_file/version'

Gem::Specification.new do |spec|
  spec.name          = 'html5_zip_file'
  spec.version       = HTML5ZipFile::VERSION
  spec.authors       = ['Patrick Paul-Hus']
  spec.email         = ['hydrozen@gmail.com']

  spec.summary       = 'HTML 5 zip file'
  spec.description   = 'HTML 5 zip file validation, unpacking and manipulation'
  spec.homepage      = 'https://github.com/adgear/html5_zip_file'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'https://adgear.jfrog.io/artifactory/api/gems/gems'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug', '~> 8.0'
  spec.add_development_dependency 'minitest', '~> 5.8'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rubocop', '~> 1.41.1'

  spec.add_dependency 'nokogiri', '~> 1.6'
  spec.add_dependency 'rubyzip', '~> 1.0'
end
