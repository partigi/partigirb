module Partigirb
  module Handlers
    class XMLHandler
      def decode_response(body)
        return REXML::Document.new if body.blank?
        xml = REXML::Document.new(body.gsub(/>\s+</,'><'))
        load_recursive(xml.root)
      end
      
      private
        def load_recursive(node)
          if array_node?(node)
            node.elements.map {|e| load_recursive(e)}
          elsif node.elements.size > 0
            build_struct(node)
          elsif node.elements.size == 0
            value = node.text
            fixnum?(value) ? value.to_i : value
          end
        end
      
        def build_struct(node)
          ts = PartigiStruct.new
          node.elements.each do |e|
            property = ""
            
            if !e.namespace.blank?
              ns = e.namespaces.invert[e.namespace]
              property << "#{ns}_" unless ns == 'xmlns'
            end
            
            property << e.name
            ts.send("#{property}=", load_recursive(e))
          end
          ts
        end
        
        # Most of the time Twitter specifies nodes that contain an array of 
        # sub-nodes with a type="array" attribute. There are some nodes that 
        # they dont' do that for, though, including the <ids> node returned 
        # by the social graph methods. This method tries to work in both situations.
        def array_node?(node)
          node.attributes['type'] == 'collection'
        end
      
        def fixnum?(value)
          value =~ /^\d+$/
        end
    end
  end
end