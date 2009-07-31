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
          elsif (node.elements.size > 0 || node.attributes.size > 0) && !ignore_attributes?(node)
            build_struct(node)          
          else
            value = node.text
            fixnum?(value) ? value.to_i : value
          end
        end
      
        def build_struct(node)
          ts = PartigiStruct.new
          
          node.attributes.each do |a,v|
            # In case the Struct object already responds to a method 
            # with same name like type case
            if ts.respond_to?(a) 
              ts.send("_#{a}=",v)
            else
              ts.send("#{a}=", v) unless a =~ /^xmlns/
            end
          end
          
          links = node.elements.delete_all('link')
          
          node.elements.each do |e|
            property = ""
            
            if ns = node_namespace(e)
              property << "#{ns}_" unless ns == 'xmlns'
            end
            
            property << e.name
            ts.send("#{property}=", load_recursive(e))
          end
          
          unless links.empty?
            ts.send("links=", links.map{|l| build_struct(l)})
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
        
        def node_namespace(node)
          node.namespace.blank? ? nil : node.namespaces.invert[node.namespace]
        end
        
        def ignore_attributes?(node)
          element_name = node.name
          ns = node_namespace(node)
          element_name.insert(0, "#{ns}:") if ns
          
          IGNORE_ATTRIBUTES_FOR.include?(element_name)
        end
        
        IGNORE_ATTRIBUTES_FOR = ['ptItem:synopsis', 'ptItem:title']
    end
  end
end