require "html5_zip_file/version"
require "html5_zip_file/file"

module HTML5ZipFile
  Error = Class.new(StandardError)
  InvalidZipArchive = Class.new(Error)
  DestinationIsNotEmpty = Class.new(Error)
  FileNotFound = Class.new(Error)
end
