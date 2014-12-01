class CodeRenderingTester < MiniTest::Unit::TestCase
  def input
    %|
  private void validateDate(Notification note) {
    if (date == null) {
      note.addError("date is missing");
      return;
    }
    LocalDate parsedDate;
    try {
      parsedDate = LocalDate.parse(getDate());
    }
  }
|
  end
end


class CodeRenderingTester
  include Mfweb::Core
  def hunks
    raw = File.read('test/codeRenderHunks.txt').split("\n%%\n")
    raw.map {|r| process_raw_hunk r}.to_h
  end
  def process_raw_hunk hunk
    lines = hunk.lines
    key = lines.find {|line| /[^[:space:]]/ =~ line}
    value = lines
      .drop_while {|line| (/[^[:space:]]/ !~ line) or (key == line)}
      .join
    return [key.chomp, value]
  end

  def form_element s
    Nokogiri::XML("<insertCode>" + s + "</insertCode").root
  end
  
  def with_highlights element, input = nil
    input ||= hunks['input']
    CodeHighlighter.new(element,input).call
  end
  def test_no_highlights
    assert_equal hunks['input'], with_highlights(form_element(""))
  end
  def test_one_line_highlight
    element = form_element "<highlight line = 'missing'/>"
    actual = with_highlights(element)
    assert_equal hunks['one-line'], actual
  end
  def test_highlight_span
    element = form_element "<highlight line = 'missing' span = 'addError'/>"
    assert_equal hunks['one-span'], with_highlights(element)
  end
  def test_highlight_range
    e = '<highlight-range start-line = "(date == null)" end-line = "}"/>'
    assert_equal hunks['range'], with_highlights(form_element(e))    
  end
  def test_highlight_range_at_start
    e = '<highlight-range start-line = "private" end-line = "}"/>'
    assert_equal hunks['range-start'], with_highlights(form_element(e))    
  end
  def test_highlight_range_at_end
    e = '<highlight-range start-line = "try" end-line = "//end"/>'
    assert_equal hunks['range-end'], with_highlights(form_element(e))    
  end
  def test_backwards_range
    e = '<highlight-range start-line = "try" end-line = "addError"/>'
    assert_raises(RuntimeError) { with_highlights(form_element(e)) } 
  end
  def test_range_no_match_start
    e = '<highlight-range start-line = "zzzzz" end-line =
    "addError"/>'
    assert_raises(RuntimeError){ with_highlights(form_element(e))}
  end
  def test_range_no_match_end
    e = '<highlight-range start-line = "try" end-line = "zzzz"/>'
    assert_raises(RuntimeError){ with_highlights(form_element(e))}
  end
  def test_span_no_match
    element = form_element "<highlight line = 'missing' span = 'zzzz'/>"
    assert_raises(RuntimeError) { with_highlights(element) }
  end
  def test_range_both_match_start_line
    element = form_element "<highlight-range start-line = 'null' end-line = '{'/>"
    assert_raises(RuntimeError) { with_highlights(element) }
  end
end


