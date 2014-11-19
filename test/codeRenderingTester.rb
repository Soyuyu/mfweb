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
    CodeHighlighter.new(element).call(input)
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
end


