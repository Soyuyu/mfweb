module InfoDeck
  class RegexpHighlighter
    def initialize input = nil, regexp = nil, span = nil
      @input = input
      @regexp = regexp
      @span = span
    end

    def self.regexp arg
      self.new.regexp arg
    end

    def self.input arg
      self.new.input arg
    end

    def self.span arg
      self.new.span arg
    end
    
    def regexp arg
      self.class.new(@input, arg, @span)
    end

    def input arg
      input_value = case 
                    when arg.kind_of?(String) then TextNode.new(arg)
                    when arg.kind_of?(RegexpHighlighter) then arg
                    else raise "unknown input class #{arg.class}"
                    end
      self.class.new(input_value, @regexp, @span)
    end

    def span arg
      self.class.new(@input, @regexp, arg)
    end
    
    def apply
      return @input.apply.map{|n| process_text_node n}.flatten
    end
    
    def process_text_node aTextNode
      m = @regexp.match(aTextNode.text)
      if m
        return [TextNode.new(m.pre_match), 
                TextNode.new(m[0], @span),
                process_text_node(TextNode.new(m.post_match))]
      else
        return aTextNode
      end
    end

    def render html_emitter, text
      self.text = text
      apply.each do |n|
        if n.css_class
          html_emitter.span(n.css_class){html_emitter.cdata n.text}
        else
          html_emitter.cdata n.text
        end
      end          
    end

    def text= aString
      if @input
        @input.text = aString
      else
        @input = TextNode.new(aString)
      end
    end

    def html
      apply.map(&:to_html).join
    end

    class TextNode
      attr_reader :text, :css_class
      def initialize text, css_class = nil
        @text = text
        @css_class = css_class
      end
      def to_html
        if @css_class
          "<span class = '#{@css_class}'>#{@text}</span>"
        else
          @text
        end
      end
      def apply
        [ self ]
      end
    end
    
  end
end
