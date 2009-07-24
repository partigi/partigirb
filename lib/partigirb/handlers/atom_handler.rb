module Partigirb
  module Handlers
    class AtomHandler < XMLHandler
      def decode_response(body)
        return REXML::Document.new if body.blank?
        xml = REXML::Document.new(body.gsub(/>\s+</,'><'))
        
        if xml.root.name == 'feed'
          entries = xml.root.get_elements('entry')
          
          # Depending on whether we have one or more entries we return an PartigiStruct or an array of PartigiStruct
          if entries.size == 1
            load_recursive(entries.first)
          else
            entries.map{|e| load_recursive(e)}
          end
        else
          # We just parse as a common XML
          load_recursive(xml.root)
        end
      end
    end
  end
end