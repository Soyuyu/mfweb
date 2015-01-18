
class IndenterTester < Minitest::Test
  include Mfweb::Core
  def test_no_change_on_zero
    @input = "first\n"+
             "  second"
    actual = Indenter.new(@input).leading(0)
    assert_equal @input, actual
  end
  def test_add_2_to_zero
    @input = "first\n" +
             "  second"
    @expected = "  first\n" +
                "    second"
    actual = Indenter.new(@input).leading(2)
    assert_equal @expected, actual
  end
  def test_first_line_amount
    assert_equal 0, Indenter.new("xx").first_line_amount
    assert_equal 2, Indenter.new("  xx").first_line_amount
    assert_equal 2, Indenter.new("  xx\nzz").first_line_amount
    assert_equal 2, Indenter.new("  <xx").first_line_amount
 end
  def test_change_1_to_2
    @input = " first\n" +
             "   second"
    @expected = "  first\n" +
                "    second"
    actual = Indenter.new(@input).leading(2)
    assert_equal @expected, actual
  end
  def test_change_2_to_0
    @input    = "  first\n" +
                "    second" 
    @expected = "first\n" +
                "  second"
    assert_equal @expected, Indenter.new(@input).leading(0)
  end
  def test_change_3_to_2
    @input    = "   first\n" +
                "     second" 
    @expected = "  first\n" +
                "    second"
    assert_equal @expected, Indenter.new(@input).leading(2)
  end
  def test_hurl_if_truncated
    @input    = "  first\n" +
                " second" 
    begin
      Indenter.new(@input).leading(0)
      flunk "didn't spot indentation truncation"
    rescue IndentationTruncationException
    end
  end
end
