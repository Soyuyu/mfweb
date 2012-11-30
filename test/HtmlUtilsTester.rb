require 'test/unit'
require 'mfweb/core'

class HtmlUtilTester < Test::Unit::TestCase
  include Mfweb::Core
  include HtmlUtils
  def test_amazon
    expected = "<a href = \"http://www.amazon.com/gp/product/0321826620?ie=UTF8&tag=martinfowlerc-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=0321826620\">some text</a><img src=\"http://www.assoc-amazon.com/e/ir?t=martinfowlerc-20&l=as2&o=1&a=0321601912\" width=\"1\" height=\"1\" border=\"0\" alt=\"\" style=\"border:none !important; margin:0px !important;\"/>"
    assert_equal(expected, amazon('0321826620', 'some text'))
  end
end
