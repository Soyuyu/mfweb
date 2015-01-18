require 'minitest/autorun'
require 'mfweb/article'

class BibliographyTester < Minitest::Test
  include Mfweb::Core
  include Mfweb::Article
  def bib_containing aString
    input = StringIO.new "<bibliography>#{aString}</bibliography>"
    result =  Bibliography.new.load input
  end
  def test_read_bib_ref_from_single_file
    bib = Bibliography.new('test/bib.xml')
    assert_equal 'http://c2.com/ppr/checks.html', bib['cunningham-checks'].url
  end
  def test_read_bib_refs_from_article_file
    bib = Bibliography.new('sample/articles/simple/simpleArticle.xml')
    assert_equal 'http://www.amazon.com/exec/obidos/ASIN/0201616416', bib['beckXPE'].url
  end
  def test_read_two_bibliographies
    bib = Bibliography.new('test/bib.xml', 'sample/articles/simple/simpleArticle.xml')
    assert_equal 'http://c2.com/ppr/checks.html', bib['cunningham-checks'].url
    assert_equal 'http://www.amazon.com/exec/obidos/ASIN/0201616416', bib['beckXPE'].url    
  end
  def test_get_cite_when_present
    bib = Bibliography.new('test/bib.xml')
    assert_equal "[cunningham-checks]", bib['cunningham-checks'].cite
  end
  def test_get_default_cite
    bib = Bibliography.new('test/bib.xml')
    assert_equal "[cvs]", bib['cvs'].cite
  end
  def test_link_around_basic
    html = HtmlEmitter.new
    bib = bib_containing "<ref name = 'mf'><url>http://martinfowler.com</url></ref>"
    assert_equal "http://martinfowler.com", bib['mf'].url

    content = Nokogiri::XML "foo"
    bib['mf'].link_around(html, content)
    assert_equal "<a href = 'http://martinfowler.com'>[mf]</a>", html.out
  end    
  def test_include_rel_with_url
    html = HtmlEmitter.new
    bib = bib_containing "<ref name = 'mf'><url rel = 'nofollow'>http://martinfowler.com</url></ref>"
    assert_equal "http://martinfowler.com", bib['mf'].url

    content = Nokogiri::XML "foo"
    bib['mf'].link_around(html, content)
    assert_equal "<a href = 'http://martinfowler.com' rel = 'nofollow'>[mf]</a>", html.out
  end
    
end
