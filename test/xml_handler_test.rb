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
  
  should "extract attributes from nodes" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.user do
        xml.id 123
        xml.name 'Bob'
        xml.field({:attribute1 => 'value1', :attribute2 => 'value2', :attribute3 => 'value3'})
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_equal 123, res.id
    assert_equal 'Bob', res.name
    
    assert res.field.is_a?(Partigirb::PartigiStruct)
    assert_equal 'value1', res.field.attribute1
    assert_equal 'value2', res.field.attribute2
    assert_equal 'value3', res.field.attribute3
  end
  
  should "extract links to an array" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.user do
        xml.id 123
        xml.link({:rel => 'alternate', :href => 'http://www.pointing-to-something.com', :type => 'text/html'})
        xml.link({:rel => 'self', :href => 'http://www.pointing-to-self-something.com', :type => 'application/xml'})
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_not_nil res.links
    assert res.links.is_a?(Array)
    assert_equal 'alternate', res.links.first.rel
    assert_equal 'self', res.links[1].rel
  end
end