Gem::Specification.new do |s|
  s.name          = 'html5_zip_file_1_8_7'
  s.version       = '1.0'
  s.authors       = ['Patrick Paul-Hus', 'Curtis McEnroe', 'Simon Claret']
  s.email         = ['hydrozen@gmail.com', 'curtis.mcenroe@adgear.com', 'simon.claret@adgear.com']

  s.summary       = 'HTML 5 zip file'
  s.description   = 'HTML 5 zip file validation and unpacking'
  s.homepage      = 'https://github.com/adgear/html5_zip_file'
  s.license       = 'MIT'

  # 1.8.7
  s.required_ruby_version = '< 1.9'

  s.files         = Dir['lib/**/*.rb']+Dir['[A-Z]*']+Dir['test/**/*']+Dir['doc/**/*']

  s.require_paths = ['lib']

  s.add_runtime_dependency 'posix-spawn'

  s.add_development_dependency "rake", "~> 10.4"
  s.add_development_dependency "minitest", "~> 5.8"

  s.requirements << 'Info-ZIP unzip v6.0'
end
