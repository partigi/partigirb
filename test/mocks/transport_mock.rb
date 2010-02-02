#Transport that collects info on requests and responses for testing purposes
class MockTransport < Partigirb::Transport
  attr_accessor :status, :body, :method, :url, :options

  def initialize(consumer,status,body,headers={})
    Net::HTTP.response = MockResponse.new(status,body,headers)
    super(consumer)
  end

  def request(method, string_url, options)
    self.method = method
    self.url = URI.parse(string_url)
    self.options = options
    super(method,string_url,options)
  end
end