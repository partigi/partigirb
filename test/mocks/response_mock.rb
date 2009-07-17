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