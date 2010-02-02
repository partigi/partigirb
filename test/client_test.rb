require File.dirname(__FILE__) + '/test_helper'

class ClientTest < Test::Unit::TestCase
  def setup
    @client = new_client
  end
  
  should "use GET method by default" do
    @client.users.show.xml
    
    assert_equal(:get, @client.transport.method)
  end
  
  should "use GET method for methods ending with ?" do
    @client.users.show.xml?
    
    assert_equal(:get, @client.transport.method)
  end
  
  should "not make a request if format is missing" do
    MockTransport.any_instance.expects(:request).never
    
    @client.users.show
    
    assert_nil @client.transport.url
  end
  
  should "use POST method for methods ending with !" do
    @client.users.show.xml!
    
    assert_equal(:post, @client.transport.method)
  end
  
  should "use POST method and default format for methods ending with !" do
    @client.friendships.create!
    
    assert_equal(:post, @client.transport.method)
    assert @client.transport.url.path.include?("/friendships/create.atom")
  end
  
  should "request to the Partigi API host through HTTP protocol" do
    @client.users.show.xml
    
    assert_equal('http', @client.transport.url.scheme)
    assert_equal(Partigirb::Client::PARTIGI_API_HOST, @client.transport.url.host)
  end
  
  should "use the current API version by default" do
    @client.users.show.xml
    
    assert_equal(Partigirb::CURRENT_API_VERSION, @client.api_version)
  end
  
  should "put the requested API version in the request url" do
    @client = new_client(200, '', {:api_version => 3})
    @client.users.show.xml
    
    assert_equal '/api/v3/users/show.xml', @client.transport.url.path
  end
  
  should "add paremeters to url on GET" do
    @client.items.index.xml :type => 'film', :page => 1, :per_page => 20
    
    assert_equal 3, request_query.size
    assert request_query.include?('type=film')
    assert request_query.include?('page=1')
    assert request_query.include?('per_page=20')
  end
  
  should "add parameters to request body on POST" do
    @client.reviews.create! :item_id => 'star-wars', :type => 'film', :status => 2, :text => 'My favorite movie', :rating => '5'
    
    assert_equal 5, post_data.size
    assert post_data.include?('item_id=star-wars')
    assert post_data.include?('type=film')
    assert post_data.include?('status=2')
    assert post_data.include?('text=My%20favorite%20movie')
    assert post_data.include?('rating=5')
  end
  
  should "add any headers to the HTTP requests" do
    @client = new_client(200, '', {:headers => {'Useless' => 'void', 'Fake' => 'header'}})
    @client.user.show.xml
    
    assert_not_nil Net::HTTP.request['Useless']
    assert_equal 'void', Net::HTTP.request['Useless']
    assert_not_nil Net::HTTP.request['Fake']
    assert_equal 'header', Net::HTTP.request['Fake']
  end
  
  should "process XML response by XML handler" do
    Partigirb::Handlers::XMLHandler.any_instance.expects(:decode_response).once
    Partigirb::Handlers::AtomHandler.any_instance.expects(:decode_response).never
    Partigirb::Handlers::JSONHandler.any_instance.expects(:decode_response).never
    @client.items.xml
  end

  should "process Atom response by Atom handler" do
    Partigirb::Handlers::XMLHandler.any_instance.expects(:decode_response).never
    Partigirb::Handlers::AtomHandler.any_instance.expects(:decode_response).once
    Partigirb::Handlers::JSONHandler.any_instance.expects(:decode_response).never
    @client.items.atom
  end

  should "process JSON response by JSON handler" do
    Partigirb::Handlers::XMLHandler.any_instance.expects(:decode_response).never
    Partigirb::Handlers::AtomHandler.any_instance.expects(:decode_response).never
    Partigirb::Handlers::JSONHandler.any_instance.expects(:decode_response).once
    @client.items.json
  end  
  
  should "raise a PartigiError with response error text as the message when http response codes are other than 200" do
    client = new_client(400, "Partigi::BadAPIRequestRequiredParams")

    begin
      client.items.show.xml :id => 'madeup'
    rescue Exception => e
      assert e.is_a?(Partigirb::PartigiError)
      assert_equal 'Partigi::BadAPIRequestRequiredParams', e.message
    end
  end
  
  should "initialize with OAuth consumer key and secret" do
    client = Partigirb::Client.new('my_consumer_key', 'my_consumer_secret')
    
    assert client.consumer.is_a?(OAuth::Consumer)
    assert_equal 'my_consumer_key', client.consumer.key
    assert_equal 'my_consumer_secret', client.consumer.secret
  end
  
  should "get a request token from the consumer" do
    consumer = mock('oauth consumer')
    request_token = mock('request token')
    OAuth::Consumer.expects(:new).with('my_consumer_key', 'my_consumer_secret', {:site => 'http://www.partigi.com'}).returns(consumer)
    client = Partigirb::Client.new('my_consumer_key', 'my_consumer_secret')
    
    consumer.expects(:get_request_token).returns(request_token)
    
    assert_equal request_token, client.request_token
  end
  
  should "clear request token and set the callback url" do
    consumer = mock('oauth consumer')
    request_token = mock('request token')      
    OAuth::Consumer.expects(:new).with('my_consumer_key', 'my_consumer_secret', {:site => 'http://www.partigi.com'}).returns(consumer)
    client = Partigirb::Client.new('my_consumer_key', 'my_consumer_secret')
    
    client.expects(:clear_request_token).once
    consumer.expects(:get_request_token).with({:oauth_callback => 'http://testing.com/oauth_callback'}).returns(request_token)
    
    client.set_callback_url('http://testing.com/oauth_callback')
  end
  
  should "create and set access token from request token, request secret and verifier" do
    client = Partigirb::Client.new('my_consumer_key', 'my_consumer_secret')
    consumer = OAuth::Consumer.new('my_consumer_key', 'my_consumer_secret', {:site => 'http://www.partigi.com'})
    client.stubs(:consumer).returns(consumer)
    
    access_token  = mock('access token')
    request_token = mock('request token')
    request_token.expects(:get_access_token).with(:oauth_verifier => 'verify_me').returns(access_token)
      
    OAuth::RequestToken.expects(:new).with(consumer, 'the_request_token', 'the_request_secret').returns(request_token)
    
    client.authorize_from_request('the_request_token', 'the_request_secret', 'verify_me')
    assert_equal access_token, client.access_token
  end
  
  should "create and set access token from access token and secret" do
    client = Partigirb::Client.new('my_consumer_key', 'my_consumer_secret')
    consumer = OAuth::Consumer.new('my_consumer_key', 'my_consumer_secret', {:site => 'http://www.partigi.com'})
    client.stubs(:consumer).returns(consumer)
    
    client.authorize_from_access('the_access_token', 'the_access_secret')
    assert client.access_token.is_a?(OAuth::AccessToken)
    assert_equal 'the_access_token', client.access_token.token
    assert_equal 'the_access_secret', client.access_token.secret
  end
  
  should "pass access token on Transport requests when available" do
    access_token  = mock('access token')
    OAuth::AccessToken.expects(:new).with(anything, 'the_access_token', 'the_access_secret').returns(access_token)
    @client.transport.expects(:request).with(anything, anything, has_entries({:access_token => access_token})).returns(MockResponse.new(200,''))
    @client.authorize_from_access('the_access_token', 'the_access_secret')
    @client.user.show.xml
  end
  
  context "verify_credentials method" do
    should "make a request to /account/verify_credentials" do
      @client = new_client(200, '')
      @client.verify_credentials

      assert_equal '/api/v1/account/verify_credentials.atom', @client.transport.url.path
    end
  end
  
  # Copied from Grackle
  should "clear the request path on clear" do
    client = new_client(200,'[{"id":1,"text":"test 1"}]')
    client.some.url.that.does.not.exist
    assert_equal('/some/url/that/does/not/exist',client.send(:request).path,"An unexecuted path should be build up")
    client.clear
    assert_equal('',client.send(:request).path,"The path shoudl be cleared")
  end
  
  should "use multipart encoding when using a file param" do
    client = new_client(200,'')
    client.account.update_profile_image! :image=>File.new(__FILE__)    
    assert_match(/multipart\/form-data/,Net::HTTP.request['Content-Type'])
  end
  
  should "escape and encode time param" do
    client = new_client(200,'')
    time = Time.now-60*60
    client.statuses.public_timeline? :since=>time  
    assert_equal("/api/v#{Partigirb::CURRENT_API_VERSION}/statuses/public_timeline.atom?since=#{CGI::escape(time.httpdate)}", Net::HTTP.request.path)
  end
end
