require 'test/unit'
require 'stringio'
require 'infodeck/regexpHighlighter'

module InfoDeck

  class DeckTransformerTester < Test::Unit::TestCase
    def test_simple_highlight
      input = "if if = if then then = then"
      actual = RegexpHighlighter.input(input).regexp(/if = if/).span('highlight').html
      expected =  "if <span class = 'highlight'>if = if</span> then then = then"
      assert_equal expected, actual
    end

    def test_two_level_highlight
      input = "In this text one is black other is white"
      white = RegexpHighlighter.regexp(/white/).span('h_white')
      black = RegexpHighlighter.regexp(/black/).span('h_black')
      composition = white.input(black.input(input))
      expected = "In this text one is <span class = 'h_black'>black</span> other is <span class = 'h_white'>white</span>"
      actual = composition.html
      assert_equal expected, actual
    end

    def test_with_global_expression
      input = "white and some white and some white"
      actual = RegexpHighlighter.span('h').input(input).regexp(/white/).html
      expected = "<span class = 'h'>white</span> and some <span class = 'h'>white</span> and some <span class = 'h'>white</span>"
      assert_equal expected, actual
    end
  end
end
