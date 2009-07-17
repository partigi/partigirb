module Partigirb
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
    
    attr_accessor :default_format, :headers, :api_version, :transport, :request, :api_host
    
    def initialize(options={})
      self.transport = Transport.new
      self.api_host = PARTIGI_API_HOST.clone
      self.api_version = options[:api_version] || Partigirb::CURRENT_API_VERSION
      self.headers = {"User-Agent"=>"Partigirb/#{Partigirb::VERSION}"}.merge!(options[:headers]||{})
      self.default_format = options[:default_format] || :xml
      
      #self.handlers = {:json=>Handlers::JSONHandler.new,:xml=>Handlers::XMLHandler.new,:unknown=>Handlers::StringHandler.new}
      #self.handlers.merge!(options[:handlers]||{})
      
      
      # TODO: Set authentication here
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
        transport.request(
          request.method, request.url, :headers=>headers, :params=>params
        )
      rescue => e
        puts e
      end        
    end
    
    def process_response(format, res)
      process_response_errors(format, res) if res.code != 200
      
      # TODO: Use ResponseParser here depending on format to return a Response object
      res
    end
    
    def process_response_errors(format, res)
      # FIXME: This is totally provisional, we should use a ResponseParser to parse errors for each format
      case format
      when :xml
        res.body =~ /<error>Partigi::(.*)<\/error>/
        puts "Error: #{$1}"
      end
    end
    
    def format_invocation?(name)
      self.request.path? && VALID_FORMATS.include?(name)
    end
  end
end