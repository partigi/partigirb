require File.dirname(__FILE__) + '/test_helper'

class RequestTest < Test::Unit::TestCase
  # TODO: Mock requests in some better way?
  
  #Used for mocking HTTP requests
  class Net::HTTP
    class << self
      attr_accessor :response, :request, :last_instance
    end
   
    def request(req)
      self.class.last_instance = self
      self.class.request = req
      self.class.response
    end
  end
  
  #Mock responses that conform mostly to HTTPResponse's interface
  class MockResponse
    include Net::HTTPHeader
    attr_accessor :code, :body
    def initialize(code,body,headers={})
      self.code = code
      self.body = body
      headers.each do |name, value|
        self[name] = value
      end
    end
  end
  
  #Transport that collects info on requests and responses for testing purposes
  class MockTransport < Partigirb::Transport
    attr_accessor :status, :body, :method, :url, :options
    
    def initialize(status,body,headers={})
      Net::HTTP.response = MockResponse.new(status,body,headers)
    end
    
    def request(method, string_url, options)
      self.method = method
      self.url = URI.parse(string_url)
      self.options = options
      super(method,string_url,options)
    end
  end
  
  context "Client without authentication" do
    should "perform a simple get request" do
      client = Partigirb::Client.new
      client.transport = MockTransport.new(200,"")
      
      client.users.show.xml :id => 'test_user'
      
      assert_equal(Partigirb::CURRENT_API_VERSION, client.api_version)
      assert_equal(Partigirb::Client::PARTIGI_API_HOST, client.api_host)
      
      assert_equal(:get, client.transport.method)
      assert_equal('http', client.transport.url.scheme)
      assert_equal(Partigirb::Client::PARTIGI_API_HOST, client.transport.url.host)
      
      assert_equal("/api/v#{client.api_version}/users/show.xml", client.transport.url.path)
      assert_equal('test_user', client.transport.options[:params][:id])
      assert_equal('id=test_user',Net::HTTP.request.path.split(/\?/)[1])
      
      # TODO: Implement xml assert select helper
      #assert_xml_select('id', :text => '123')
    end
    
    should "perform a simple post request" do
      client = Partigirb::Client.new
      client.transport = MockTransport.new(200,"")
      
      client.reviews.update! :status => 2
      
      assert_equal(:post,client.transport.method,"Expected post request")
      assert_equal('http',client.transport.url.scheme,"Expected scheme to be http")
      assert_equal(Partigirb::Client::PARTIGI_API_HOST, client.transport.url.host)
      assert_equal("/api/v#{client.api_version}/reviews/update.xml", client.transport.url.path)
      assert_equal(2, client.transport.options[:params][:status])
      assert_equal('status=2',Net::HTTP.request.path.split(/\?/)[1])
    end
  end
end
