require 'minitest/autorun'
require 'mfweb/core'

class HtmlUtilTester < Minitest::Test
  include Mfweb::Core
  include HtmlUtils
  def test_amazon
    expected = "<a href = \"http://www.amazon.com/gp/product/0321826620?ie=UTF8&amp;tag=martinfowlerc-20&amp;linkCode=as2&amp;camp=1789&amp;creative=9325&amp;creativeASIN=0321826620\">some text</a><img src=\"http://www.assoc-amazon.com/e/ir?t=martinfowlerc-20&amp;l=as2&amp;o=1&amp;a=0321601912\" width=\"1\" height=\"1\" border=\"0\" alt=\"\" style=\"width: 1px !important; height: 1px !important; border:none !important; margin:0px !important;\"/>"
    assert_equal(expected, amazon('0321826620', 'some text'))
  end
end
