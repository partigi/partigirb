require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'builder'
require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'partigirb'

# TODO: Mock requests in some better way?
Dir.glob('test/mocks/*_mock.rb').each { |e| require e } 

class Test::Unit::TestCase
  def new_client(status=200, response_body='', client_opts={})
    client = Partigirb::Client.new(client_opts)
    client.transport = MockTransport.new(status,response_body)
    client
  end
  
  def request_query
    if Net::HTTP.request && !Net::HTTP.request.path.nil? && !Net::HTTP.request.path.empty?
      Net::HTTP.request.path.split(/\?/)[1].split('&')
    else
      nil
    end
  end
  
  def post_data
    Net::HTTP.request.body.split('&')
  end
  
  def build_xml_string(&block)
    s = nil
    xml = Builder::XmlMarkup.new(:target => s)
    block.call(xml)
    s
  end
  
end
