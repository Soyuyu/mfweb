require 'test/unit'
require 'mfweb/article'

class PaperTransformerTester < Test::Unit::TestCase
  include Mfweb::Core
  include Mfweb::Article

  def strip_revision_footer aString
    result = StringIO.new
    aString.each_line do |line|
      if line == "<div class = 'appendix'>\n"
        break
      else
        result << line
      end
    end
    return result.string
  end

  def transform input
    root = MfXml.root input
    result = StringIO.new
    out = HtmlEmitter.new(result)
    tfr = PaperTransformer.new(out, root, nil)
    tfr.render
    return strip_revision_footer(result.string).strip   
  end

  def test_with_entities
    input = "<p>some text &amp; stuff</p>"
    expected = input 
    assert_equal(expected, transform(input))
  end
  def test_cdata
    input = "<p><![CDATA[content with <<]]></p>"
    expected = "<p>content with &lt;&lt;</p>"
    assert_equal(expected, transform(input))
  end

  def test_ampersands_in_attribute
    input = "<a href = 'foo?a1=1&amp;a2=2'/>"
    expected = "<a href = 'foo?a1=1&amp;a2=2'></a>"
    assert_equal(expected, transform(input))
  end

  def xtest_html_entities
    #TODO retired for the moment but need to think properly how to fix it
    doctype = []
    doctype << "<!DOCTYPE paper [" 
    doctype << '<!ENTITY % htmlentities SYSTEM "xhtml-lat1.ent">'
    doctype << '%htmlentities;'
    doctype << ']>'
    text = "<p>Tirs&eacute;n</p>"
    expected = text
    input = doctype.join("\n") + text
    # nok = Nokogiri::XML(input)
    # puts '','--', nok.errors, '--'
    # puts nok.root
    assert_equal(expected, transform(input))
  end

  def test_comments
    input = "<p><!-- ignore this --></p>"
    expected = "<p></p>"
    assert_equal(expected, transform(input))
  end

  def test_amazon
    input = "<book isbn = '0321826620'>my book</book>"
    expected = "<a href = \"http://www.amazon.com/gp/product/0321826620?ie=UTF8&amp;tag=martinfowlerc-20&amp;linkCode=as2&amp;camp=1789&amp;creative=9325&amp;creativeASIN=0321826620\">my book</a><img src=\"http://www.assoc-amazon.com/e/ir?t=martinfowlerc-20&amp;l=as2&amp;o=1&amp;a=0321601912\" width=\"1\" height=\"1\" border=\"0\" alt=\"\" style=\"border:none !important; margin:0px !important;\"/>"
    assert_equal(expected, transform(input))    
  end
end
