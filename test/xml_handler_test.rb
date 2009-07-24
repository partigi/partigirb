require File.dirname(__FILE__) + '/test_helper'

class XMLHandlerTest < Test::Unit::TestCase
  def setup
    @handler = Partigirb::Handlers::XMLHandler.new
  end
  
  should "extract root nodes" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.user do
        xml.id 12
        xml.name 'Wadus'
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_equal 12, res.id
    assert_equal 'Wadus', res.name
  end
  
  should "extract nested nodes" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.user do
        xml.id 1
        xml.friends :type => 'collection' do
          xml.friend do
            xml.id 2
            xml.name 'Wadus'
          end
          xml.friend do
            xml.id 3
            xml.name 'Gradus'
          end
        end
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_equal 1, res.id
    assert res.friends.is_a?(Array)
    assert_equal 2, res.friends[0].id
    assert_equal 3, res.friends[1].id
    assert_equal 'Wadus', res.friends[0].name
    assert_equal 'Gradus', res.friends[1].name
  end
  
  should "extract nodes using namespaces" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.user({"xmlns:nameSpace" => 'http://schemas.overtheworld.com/v200/nameSpace'}) do
        xml.nameSpace :id, 123
        xml.nameSpace :name, 'Bob'
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_equal 123, res.nameSpace_id
    assert_equal 'Bob', res.nameSpace_name
  end
end