module Partigirb
  VERSION='0.0.0'
  CURRENT_API_VERSION=1
end

$:.unshift File.dirname(__FILE__)

require 'open-uri'
require 'net/http'

require 'partigirb/transport'
require 'partigirb/client'