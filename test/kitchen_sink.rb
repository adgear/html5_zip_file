require 'html5_zip_file'
require 'tmpdir'

ZipUnpack::ZipFile.set_log_level Logger::INFO

HTML5ZipFile::File.open('test/data/test-ad.zip') do |f|

  puts "size_unpacked: #{f.size_unpacked}"

  f.entries.each { |e| puts(e.inspect()) }

  if f.validate( :size_unpacked => 700000,
                 :file_count => 3,
                 :path_length => 14,
                 :contains_html_file => false )

    Dir.mktmpdir("HTML5ZipFile_extract_") do |dir|
      f.unpack(dir)
    end

  else

    puts 'Failed validation checks: '
    f.failures.each { |failure|  puts(failure) }

  end

end
