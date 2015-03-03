module Mfweb::Core
  class CodeRenderer
    def initialize html, code_fragment, anElement
      @html = html
      @fragment = code_fragment
      @anElement = anElement
    end
    
    def call
      leading = heading ? 2 : 0
      body = Indenter.new(@fragment.result.gsub("\t", "  ")).leading(leading)
      @html.p('code-label') {@html.text heading} if heading
      attr = @anElement['cssClass'] ? {class: @anElement['cssClass']} : {}
      @html.element('pre', attr) {emit_code_body body}
    end

    def emit_code_body body
      if @anElement.kind_of? Nokogiri::XML::Element and not @anElement.children.empty?
        @html << highlighted_code(body)
      else
        @html.cdata(body)
      end
    end

    def highlighted_code body
      CodeHighlighter.new(@anElement, body).call
    end

    def heading
      case
      when 'true' == @anElement['useClassName']
        "#{@fragment.class}...\n"
      when @anElement['label']
        "#{@anElement['label']}\n"
      when @anElement['class'] #TODO remove class element from old docs
        "class #{@anElement['class']}...\n"
      else nil
      end
    end

  end
end
