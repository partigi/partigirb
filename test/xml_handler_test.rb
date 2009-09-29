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
  
  should "extract values and ignore attributes for elements in IGNORE_ATTRIBUTES_FOR" do
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.entry({"xmlns:ptItem" => 'http://schemas.overtheworld.com/v200/ptItem'}) do
        xml.id 123
        xml.ptItem :synopsis, {:lang => 'en', :type => 'text'}, 'In my opinion...'
        xml.ptItem :title, {:lang => 'en'}, 'Wadus Movie'
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.is_a?(Partigirb::PartigiStruct)
    assert_equal 'In my opinion...', res.ptItem_synopsis
    assert_equal 'Wadus Movie', res.ptItem_title
  end
  
  should "create an struct with a method for each type for nodes defined as multiple type nodes" do
    expected_content = <<-CONTENT
      <h1>Testing</h1>
      <p>This is raw html content</p>
    CONTENT
    
    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.entry({"xmlns:ptItem" => 'http://schemas.overtheworld.com/v200/ptItem'}) do
        xml.id 123
        xml.content("This is text content", :type => 'text')
        xml.content(:type => 'html') do
          xml << <<-CONTENT
          <![CDATA[
            #{expected_content}
          ]]>
          CONTENT
        end
      end
    end
    
    res = @handler.decode_response(xmls)
    assert res.respond_to?('content')
    assert res.content.respond_to?('text')
    assert res.content.respond_to?('html')
    
    assert_equal "This is text content", res.content.text
    assert_equal "<h1>Testing</h1><p>This is raw html content</p>", res.content.html.strip
  end
  
  should "not parse elements with type property set to xhtml even if they are not in IGNORE_ATTRIBUTES_FOR" do
    expected_content = <<-XHTML
      <div xmlns="http://www.w3.org/1999/xhtml">
        <a href="http://www.partigi.com/films/watchmen">
          <img alt="Watchmen's poster" src="http://s3.amazonaws.com/partigiproduction/films/posters/179/watchmen_thumb.jpg"/>
        </a>
      </div>
      <div xmlns="http://www.w3.org/1999/xhtml">
        <blockquote>Great movie. I recommend to read the comic before watching the movie.</blockquote>
      </div>
    XHTML

    xmls = build_xml_string do |xml|
      xml.instruct!
      xml.entry({"xmlns:ptItem" => 'http://schemas.overtheworld.com/v200/ptItem'}) do
        xml.id 123
        xml.plaindata(:type => 'xhtml') do
          xml << <<-CONTENT
          <![CDATA[
            #{expected_content}
          ]]>
          CONTENT
        end
      end
    end

    res = @handler.decode_response(xmls)
    assert_equal expected_content.strip.gsub(/\n\s+/,''), res.plaindata.strip
  end
end