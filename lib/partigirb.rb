module Partigirb
  VERSION='0.1.0'
  CURRENT_API_VERSION=1
end

$:.unshift File.dirname(__FILE__)

require 'open-uri'
require 'net/http'
require 'base64'
require 'digest'
require 'rexml/document'
require 'mime/types'
require 'ostruct'

require 'partigirb/core_ext'

require 'partigirb/transport'
require 'partigirb/client'
Dir.glob('lib/partigirb/handlers/*.rb').each { |e| require e } 
