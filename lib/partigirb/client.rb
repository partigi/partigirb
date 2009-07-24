module Partigirb
  
  class PartigiStruct < OpenStruct
    attr_accessor :id 
  end
  
  #Raised by methods which call the API if a non-200 response status is received 
  class PartigiError < StandardError
    attr_accessor :method, :request_uri, :status, :response_body, :response_object
  
    def initialize(method, request_uri, status, response_body, msg=nil)
      self.method = method
      self.request_uri = request_uri
      self.status = status
      self.response_body = response_body
      super(msg||"#{self.method} #{self.request_uri} => #{self.status}: #{self.response_body}")
    end
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
    
    attr_accessor :default_format, :headers, :api_version, :transport, :request, :api_host, :auth, :handlers
    
    def initialize(options={})
      self.transport = Transport.new
      self.api_host = PARTIGI_API_HOST.clone
      self.api_version = options[:api_version] || Partigirb::CURRENT_API_VERSION
      self.headers = {"User-Agent"=>"Partigirb/#{Partigirb::VERSION}"}.merge!(options[:headers]||{})
      self.default_format = options[:default_format] || :atom
      self.handlers = {
        :json => Partigirb::Handlers::JSONHandler.new,
        :xml => Partigirb::Handlers::XMLHandler.new,
        :unknown => Partigirb::Handlers::StringHandler.new
      }
      self.handlers[:atom] = self.handlers[:xml]
      
      self.handlers.merge!(options[:handlers]||{})
      
      # Authentication param should be a hash with keys:
      # login (required)
      # api_secret (required)
      # nonce (optional, would be automatically generated if missing)
      # timestamp (optional, current timestamp will be automatically used if missing)
      self.auth = options[:auth]
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
        set_authentication_headers
        
        transport.request(
          request.method, request.url, :headers=>headers, :params=>params
        )
      rescue => e
        puts e
      end        
    end
    
    def process_response(format, res)
      fmt_handler = handler(format)        
      begin
        unless res.code == 200
          handle_error_response(res, Partigi::Handlers::XMLHandler)
        else
          fmt_handler.decode_response(res.body)
        end
      rescue PartigiError => e
        raise e
      rescue => e
        raise PartigiError.new(res.method,res.request_uri,res.status,res.body,"Unable to decode response: #{e}")
      end
      
    end
    
    # TODO: Test for errors
    def handle_error_response(res, handler)
      err = PartigiError.new(res.method,res.request_uri,res.status,res.body)
      err.response_object = handler.decode_response(err.response_body)
      raise err        
    end
    
    def format_invocation?(name)
      self.request.path? && VALID_FORMATS.include?(name)
    end
    
    def handler(format)
      handlers[format] || handlers[:unknown]
    end
    
    # Adds the proper WSSE headers if there are the right authentication parameters
    def set_authentication_headers
      unless self.auth.nil? || self.auth === Hash || self.auth.empty?
        auths = self.auth.stringify_keys
      
        if auths.has_key?('login') &&  auths.has_key?('api_secret')
          if !auths['timestamp'].nil?
            timestamp = case auths['timestamp']
            when Time
              auths['timestamp'].strftime(TIMESTAMP_FORMAT)
            when String
              auths['timestamp']
            end
          else
            timestamp = Time.now.strftime(TIMESTAMP_FORMAT) if timestamp.nil?
          end
        
          nonce = auths['nonce'] || generate_nonce
          password_digest = generate_password_digest(nonce, timestamp, auths['login'], auths['api_secret'])
          headers.merge!({
            'Authorization' => "WSSE realm=\"#{PARTIGI_API_HOST}\", profile=\"UsernameToken\"",
            'X-WSSE' => "UsernameToken Username=\"#{auths['login']}\", PasswordDigest=\"#{password_digest}\", Nonce=\"#{nonce}\", Created=\"#{timestamp}\""
          })
        end
      end
    end
    
    def generate_nonce
      o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
      Digest::MD5.hexdigest((0..10).map{o[rand(o.length)]}.join)
    end
    
    def generate_password_digest(nonce, timestamp, login, secret)
      Base64.encode64(Digest::SHA1.hexdigest("#{nonce}#{timestamp}#{login}#{secret}")).chomp
    end
  end
end