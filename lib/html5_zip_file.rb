require 'rubygems'

module HTML5ZipFile
  Error = Class.new(StandardError)
  DestinationNotEmpty = Class.new(Error)
  NotUnpacked = Class.new(Error)
  InvalidScriptTag = Class.new(Error)
end
require "html5_zip_file/file"
