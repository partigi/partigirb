module Partigirb
  VERSION='0.0.0'
end

$:.unshift File.dirname(__FILE__)

require 'open-uri'
require 'net/http'

require 'partigirb/request'