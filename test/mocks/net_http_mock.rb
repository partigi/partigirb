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