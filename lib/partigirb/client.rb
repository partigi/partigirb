module Partigirb
  
  class PartigiStruct < OpenStruct
    attr_accessor :id 
  end
  
  # Raised by methods which call the API if a non-200 response status is received 
  class PartigiError < StandardError
  end
  
  class Client
    class Request #:nodoc:
      attr_accessor :client, :path, :method, :api_version
      
      def initialize(client,api_version=Partigirb::CURRENT_API_VERSION)
        self.client = client
        self.api_version = api_version
        self.method = :get
        self.path = ''
      end
      
      def <<(path)
        self.path << path
      end
      
      def path?
        path.length > 0
      end
    
      def url
        "#{scheme}://#{host}/api/v#{self.api_version}#{path}"
      end
         
      def host
        client.api_host
      end
    
      def scheme
        'http'
      end
    end
    
    VALID_METHODS = [:get,:post,:put,:delete]
    VALID_FORMATS = [:atom,:xml,:json]

    PARTIGI_API_HOST = "www.partigi.com"
    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%SZ'
    
    attr_accessor :consumer_key, :consumer_secret, :default_format, :headers, :api_version, :transport, :request, :api_host, :auth, :handlers, :access_token
    
    def initialize(consumer_key, consumer_secret, options={})
      @consumer = ::OAuth::Consumer.new(consumer_key, consumer_secret, {:site => "http://#{PARTIGI_API_HOST}"})
      @transport = Transport.new(@consumer)
      @api_host = PARTIGI_API_HOST.clone
      @api_version = options[:api_version] || Partigirb::CURRENT_API_VERSION
      @headers = {"User-Agent"=>"Partigirb/#{Partigirb::VERSION}"}.merge!(options[:headers]||{})
      @default_format = options[:default_format] || :atom
      @handlers = {
        :json => Partigirb::Handlers::JSONHandler.new,
        :xml => Partigirb::Handlers::XMLHandler.new,
        :atom => Partigirb::Handlers::AtomHandler.new,
        :unknown => Partigirb::Handlers::StringHandler.new
      }
      @handlers.merge!(options[:handlers]) if options[:handlers]
    end
    
    def method_missing(name,*args)
      # If method is a format name, execute using that format
      if format_invocation?(name)
        return call_with_format(name,*args)
      end
      # If method ends in ! or ? use that to determine post or get
      if name.to_s =~ /^(.*)(!|\?)$/
        name = $1.to_sym
        # ! is a post, ? is a get
        self.request.method = ($2 == '!' ? :post : :get)          
        if format_invocation?(name)
          return call_with_format(name,*args)
        else
          self.request << "/#{$1}"
          return call_with_format(self.default_format,*args)
        end
      end
      # Else add to the request path
      self.request << "/#{name}"
      self
    end
    
    # Clears any pending request built up by chained methods but not executed
    def clear
      self.request = nil
    end
    
    def request
      @request ||= Request.new(self,api_version)
    end
    
    # OAuth related methods
    
    # Note: If using oauth with a web app, be sure to provide :oauth_callback.
    def request_token(options={})
      @request_token ||= consumer.get_request_token(options)
    end
    
    def set_callback_url(url)
      clear_request_token
      request_token(:oauth_callback => url)
    end
    
    # For web apps use params[:oauth_verifier], for desktop apps,
    # use the verifier is the pin that twitter gives users.
    def authorize_from_request(request_token, request_secret, verifier_or_pin)
      request_token = OAuth::RequestToken.new(consumer, request_token, request_secret)
      @access_token = request_token.get_access_token(:oauth_verifier => verifier_or_pin)
    end
    
    def consumer
      @consumer
    end
    
    def access_token
      @access_token
    end
    
    def authorize_from_access(token, secret)
      @access_token = OAuth::AccessToken.new(consumer, token, secret)
    end
    
    # Shortcut methods
    
    def verify_credentials
      account.verify_credentials?
    end
    
    protected
    
    def call_with_format(format,params={})
      request << ".#{format}"
      res = send_request(params)
      process_response(format,res)
    ensure
      clear
    end
    
    def send_request(params)
      begin
        options = {:headers=>headers, :params=>params}
        options.merge!(:access_token => @access_token) unless @access_token.nil?
        transport.request(request.method, request.url, options)
      rescue => e
        puts e
      end        
    end
    
    def process_response(format, res)
      fmt_handler = handler(format)
      
      begin
        if res.code.to_i != 200
          handle_error_response(res)
        else
          fmt_handler.decode_response(res.body)
        end
      end
    end
    
    def handle_error_response(res)
      raise PartigiError.new(res.body)
    end
    
    def format_invocation?(name)
      self.request.path? && VALID_FORMATS.include?(name)
    end
    
    def handler(format)
      handlers[format] || handlers[:unknown]
    end
    
    def clear_request_token
      @request_token = nil
    end
  end
end