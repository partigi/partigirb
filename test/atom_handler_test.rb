require File.dirname(__FILE__) + '/test_helper'

class AtomHandlerTest < Test::Unit::TestCase
  def setup
    @handler = Partigirb::Handlers::AtomHandler.new
  end
  
  should "return a PartigiStruct with entry elements for feeds with just one entry" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      
      xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
        xml.title   "A feed"
        xml.id      "http://the.feed.url.com"
        xml.updated "2009-07-24T10:40:22Z"
      
        xml.entry({"xmlns:ptUser" => 'http://schemas.partigi.com/v1.0/ptUser'}) do
          xml.category({:scheme => "http://schemas.partigi.com/v1.0#kind", :term => "http://schemas.partigi.com/v1.0#user"})
          xml.id          "http://the.feed.url2.com"
          xml.title       "User entry"
          xml.ptUser :id, 321
          xml.ptUser :login, "user_login"
          xml.ptUser :name, "User Name"
        end
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    
    assert_equal "User entry", res.title
    assert_equal "http://the.feed.url2.com", res.id
    assert_equal 321, res.ptUser_id
    assert_equal "user_login", res.ptUser_login
    assert_equal "User Name", res.ptUser_name
    assert_nil res.updated
  end
  
  should "return an array of PartigiStruct with PartigiStruct of each entry in the feed" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      
      xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
        xml.title   "A feed"      
        xml.entry({"xmlns:ptUser" => 'http://schemas.partigi.com/v1.0/ptUser'}) do
          xml.ptUser :id, 321
        end
        xml.entry({"xmlns:ptUser" => 'http://schemas.partigi.com/v1.0/ptUser'}) do
          xml.ptUser :id, 123
        end
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Array)
    assert_equal 2, res.size
    
    assert_equal 321, res[0].ptUser_id
    assert_equal 123, res[1].ptUser_id
  end
end