require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'builder'
require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'partigirb'

Dir.glob('test/mocks/*_mock.rb').each { |e| require e } 

class Test::Unit::TestCase
  def new_client(status=200, response_body='', client_opts={})
    client = Partigirb::Client.new('prb_consumer_key', 'prb_consumer_secret', client_opts)
    client.transport = MockTransport.new(client.consumer,status,response_body)
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
    s = String.new
    xml = Builder::XmlMarkup.new(:target => s)
    yield(xml)
    s
  end
  
  def load_fixture(name, format = :xml)
    name += '.xml' if format.to_s == 'xml'
    name += '.atom.xml' if format.to_s == 'atom'
    name += '.json' if format.to_s == 'json'
    
    File.read(File.join(File.dirname(__FILE__), 'fixtures', name))
  end
end
