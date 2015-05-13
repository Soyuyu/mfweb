module Mfweb::Core
  class CodeHighlighter
    def initialize insertCodeElement, fragment
      @data = insertCodeElement
      @fragment = fragment.encode(xml: :text)
    end
    def self.highlighting_elements
      %w[highlight highlight-range]
    end
    def opening element
      css_class = element['css-class'] || 'highlight'
      "<span class = '#{css_class}'>"
    end
    def closing
      "</span>"
    end
    def highlights
      @data.css('highlight')
    end
    def highlight_ranges
      @data.css('highlight-range')
    end
    def call
      apply_highlights(apply_ranges(@fragment.lines))
    end
    def apply_ranges lines
      highlight_ranges.reduce(lines){|acc, each| apply_one_range(acc, each)}
    end
    def apply_one_range lines, element
      start_ix = lines.find_index {|line| line =~ Regexp.new(element['start-line'])}
      raise "unable to match %s in code insert" % element['start-line'] unless start_ix
      finish_offset = lines[start_ix..-1].find_index do |line| 
        line =~ Regexp.new(element['end-line'])
      end
      raise "unable to match %s in code insert" % element['end-line'] unless finish_offset
      raise "start and end match same line" unless finish_offset > 0
      finish_ix = start_ix + finish_offset
      pre = 0 == start_ix ? [] : lines[0..(start_ix - 1)]
      start = [opening(element) + lines[start_ix]]
      mid = (lines[(start_ix + 1)..(finish_ix - 1)])
      finish = [lines[finish_ix].chomp + closing + "\n"]
      rest = lines.size == (finish_ix + 1) ? [] : lines[(finish_ix + 1)..-1]
      return pre + start + mid + finish + rest
    end
    
    def apply_highlights lines
      lines.map{|line| highlight_line line}.join
    end
    def highlight_line line
      highlights
        .select{|h| Regexp.new(h['line']).match(line)}
        .reduce(line){|acc, each| apply_markup acc, each}
    end
    def apply_markup line, element
      if element.key? 'span'
        r = Regexp.new(element['span'])
        m = r.match line
        raise "unable to match span %s" % element['span'] unless m
        m.pre_match + opening(element) + m[0] + closing + m.post_match
      else
        opening(element) + line.chomp + closing + "\n"
      end
    end
  end
end
