module Partigirb
  VERSION='0.3.0'
  CURRENT_API_VERSION=1
end

$:.unshift File.dirname(__FILE__)

require 'rubygems'

require 'open-uri'
require 'net/http'
require 'base64'
require 'digest'
require 'rexml/document'
require 'mime/types'
require 'ostruct'
require 'oauth'

require 'partigirb/core_ext'

require 'partigirb/handlers/xml_handler'
require 'partigirb/handlers/atom_handler'
require 'partigirb/handlers/json_handler'
require 'partigirb/handlers/string_handler'

require 'partigirb/transport'
require 'partigirb/client'