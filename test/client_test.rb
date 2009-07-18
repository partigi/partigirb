require File.dirname(__FILE__) + '/test_helper'

class ClientTest < Test::Unit::TestCase
  should "use GET method by default" do
    client = new_client
    client.users.show.xml
    
    assert_equal(:get, client.transport.method)
  end
  
  should "use GET method for methods ending with ?" do
    client = new_client
    client.users.show.xml?
    
    assert_equal(:get, client.transport.method)
  end
  
  should "not make a request if format is missing" do
    MockTransport.any_instance.expects(:request).never
    
    client = new_client
    client.users.show
    
    assert_nil client.transport.url
  end
  
  should "use POST method for methods ending with !" do
    client = new_client
    client.users.show.xml!
    
    assert_equal(:post, client.transport.method)
  end
  
  should "use POST method and default format for methods ending with !" do
    client = new_client
    client.friendships.create!
    
    assert_equal(:post, client.transport.method)
    assert client.transport.url.path.include?("/friendships/create.xml")
  end
  
  should "request to the Partigi API host through HTTP protocol" do
    client = new_client
    client.users.show.xml
    
    assert_equal('http', client.transport.url.scheme)
    assert_equal(Partigirb::Client::PARTIGI_API_HOST, client.transport.url.host)
  end
  
  should "use the current API version by default" do
    client = new_client
    client.users.show.xml
    
    assert_equal(Partigirb::CURRENT_API_VERSION, client.api_version)
  end
  
  should "put the requested API version in the request url" do
    client = new_client(200, '', {:api_version => 3})
    client.users.show.xml
    
    assert_equal '/api/v3/users/show.xml', client.transport.url.path
  end
  
  should "add paremeters to url on GET" do
    client = new_client
    client.items.index.xml :type => 'film', :page => 1, :per_page => 20
    
    assert_equal 3, request_query.size
    assert request_query.include?('type=film')
    assert request_query.include?('page=1')
    assert request_query.include?('per_page=20')
  end
  
  should "add parameters to request body on POST" do
    client = new_client
    client.reviews.create! :item_id => 'star-wars', :type => 'film', :status => 2, :text => 'My favorite movie', :rating => '5'
    
    assert_equal 5, post_data.size
    assert post_data.include?('item_id=star-wars')
    assert post_data.include?('type=film')
    assert post_data.include?('status=2')
    assert post_data.include?('text=My%20favorite%20movie')
    assert post_data.include?('rating=5')
  end
  
  should "add any headers to the HTTP requests" do
    client = new_client(200, '', {:headers => {'Useless' => 'void', 'Fake' => 'header'}})
    client.user.show.xml
    
    assert_not_nil Net::HTTP.request['Useless']
    assert_equal 'void', Net::HTTP.request['Useless']
    assert_not_nil Net::HTTP.request['Fake']
    assert_equal 'header', Net::HTTP.request['Fake']
  end
  
  # TODO: Test for responses
end
