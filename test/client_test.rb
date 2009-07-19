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
    assert @client.transport.url.path.include?("/friendships/create.xml")
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
  
  should "add authentication headers when login and secret are provided" do
    @client = new_client(200, '', :auth => {:login => 'auser', :api_secret => 'his_api_secret'})
    
    @client.friendships.update! :id => 321
    
    assert_not_nil Net::HTTP.request['Authorization']
    assert_equal "WSSE realm=\"#{Partigirb::Client::PARTIGI_API_HOST}\", profile=\"UsernameToken\"", Net::HTTP.request['Authorization']
    
    assert_not_nil Net::HTTP.request['X-WSSE']
    assert_match /UsernameToken Username="auser", PasswordDigest="[^"]+", Nonce="[^"]+", Created="[^"]+"/, Net::HTTP.request['X-WSSE']
  end
  
  should "not add authentication headers if no auth params are provided" do
    @client.friendships.update! :id => 321
    
    assert_nil Net::HTTP.request['Authorization']
    assert_nil Net::HTTP.request['X-WSSE']
  end
  
  should "use given nonce for authentication" do
    @client = new_client(200, '', :auth => {:login => 'auser', :api_secret => 'his_api_secret', :nonce => '123456789101112'})
    @client.friendships.update! :id => 321
    
    assert_equal "WSSE realm=\"#{Partigirb::Client::PARTIGI_API_HOST}\", profile=\"UsernameToken\"", Net::HTTP.request['Authorization']
    assert_match /UsernameToken Username="auser", PasswordDigest="[^"]+", Nonce="123456789101112", Created="[^"]+"/, Net::HTTP.request['X-WSSE']
  end
  
  should "use given timestamp string for authentication" do
    @client = new_client(200, '', :auth => {:login => 'auser', :api_secret => 'his_api_secret', :timestamp => '2009-07-15T14:43:07Z'})
    @client.friendships.update! :id => 321
    
    assert_equal "WSSE realm=\"#{Partigirb::Client::PARTIGI_API_HOST}\", profile=\"UsernameToken\"", Net::HTTP.request['Authorization']
    assert_match /UsernameToken Username="auser", PasswordDigest="[^"]+", Nonce="[^"]+", Created="2009-07-15T14:43:07Z"/, Net::HTTP.request['X-WSSE']
  end
  
  should "use given Time object as timestamp for authentication" do
    timestamp = Time.now
    @client = new_client(200, '', :auth => {:login => 'auser', :api_secret => 'his_api_secret', :timestamp => timestamp})
    @client.friendships.update! :id => 321
    
    assert_equal "WSSE realm=\"#{Partigirb::Client::PARTIGI_API_HOST}\", profile=\"UsernameToken\"", Net::HTTP.request['Authorization']
    assert_match /UsernameToken Username="auser", PasswordDigest="[^"]+", Nonce="[^"]+", Created="#{timestamp.strftime(Partigirb::Client::TIMESTAMP_FORMAT)}"/, Net::HTTP.request['X-WSSE']
  end
  
  should "use the PasswordDigest from given parameters" do
    @client = new_client(200, '', :auth => {:login => 'auser', :api_secret => 'his_api_secret', :nonce => '123456789101112', :timestamp => '2009-07-15T14:43:07Z'})
    @client.friendships.update! :id => 321
    
    pdigest = Base64.encode64(Digest::SHA1.hexdigest("1234567891011122009-07-15T14:43:07Zauserhis_api_secret")).chomp
    
    assert_equal "WSSE realm=\"#{Partigirb::Client::PARTIGI_API_HOST}\", profile=\"UsernameToken\"", Net::HTTP.request['Authorization']
    assert_match /UsernameToken Username="auser", PasswordDigest="#{pdigest}", Nonce="123456789101112", Created="2009-07-15T14:43:07Z"/, Net::HTTP.request['X-WSSE']
  end
  
  context "generate_nonce method" do
    should "generate random strings" do
      @client.instance_eval do
        nonces = []
        1.upto(25) do
          assert !nonces.include?(generate_nonce)
        end
      end
    end
  end
  
  # TODO: Test for responses
end
