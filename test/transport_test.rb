require File.dirname(__FILE__) + '/test_helper'
require 'net/http'

class TransportTest < Test::Unit::TestCase
  should "sign request using OAuth without access token by default" do
    consumer = ::OAuth::Consumer.new('consumer_key', 'this_is_secret')
    transport = Partigirb::Transport.new(consumer)
    
    Net::HTTP::Get.any_instance.expects(:oauth!).with(anything, consumer, nil).once
    Net::HTTP.any_instance.expects(:request).once
    
    transport.request :get, "http://test.host"
  end
  
  should "sign request using OAuth with the given Access Token" do
    consumer = ::OAuth::Consumer.new('consumer_key', 'this_is_secret')
    access_token = ::OAuth::AccessToken.new('access_token', 'access_secret')
    transport = Partigirb::Transport.new(consumer)
    
    Net::HTTP::Get.any_instance.expects(:oauth!).with(anything, consumer, access_token).once
    Net::HTTP.any_instance.expects(:request).once
    
    transport.request :get, "http://test.host", :access_token => access_token
  end
end