Gem::Specification.new do |s|
  s.name          = 'html5_zip_file'
  s.version       = '1.0'
  s.authors       = ['Patrick Paul-Hus', 'Curtis McEnroe', 'Simon Claret']
  s.email         = ['hydrozen@gmail.com', 'curtis.mcenroe@adgear.com', 'simon.claret@adgear.com']

  s.summary       = 'HTML 5 zip file'
  s.description   = 'HTML 5 zip file validation and unpacking'
  s.homepage      = 'https://github.com/adgear/html5_zip_file'
  s.license       = 'MIT'

  s.required_ruby_version = '>= 2.2.2'

  s.files         = Dir['lib/**/*.rb']+Dir['[A-Z]*']+Dir['test/**/*']+Dir['doc/**/*']

  s.require_paths = ['lib']

  s.add_runtime_dependency 'posix-spawn'

  # built-in to ruby 2.2.2, but Travis CI still needs it in the Gemfile
  s.add_development_dependency 'rake'

  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'yard', '~> 0.8.7'
  s.add_development_dependency 'yard-doctest', '~> 0.1.5'

  s.requirements << 'Info-ZIP unzip v6.0'
end
