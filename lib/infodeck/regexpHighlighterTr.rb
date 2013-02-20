module InfoDeck
  class RegexpHighlighterTransformer < Transformer
    include Mfweb::Article
    def initialize out_emitter, in_root, maker
      super(out_emitter, in_root)
      @maker = maker
    end
    def handle_insertCode anElement
      begin
        code_frag = @maker.code_server.find(anElement['file'],anElement['fragment']) 
        if anElement['label'] || anElement['useClassName']
          #TODO put this support in while refactoring code server.render_insertCode
          log.warn "no support yet for all insertcode features while highlighting"
        end
        highlighter = compose_highlighter anElement
        @html.element('pre') { highlighter.render(@html, code_frag.result) }
      rescue MissingFragmentFile
        puts "missing file: #{anElement['file']}"
        raise $!
      rescue MissingFragment
        puts "missing fragment: #{anElement['fragment']}"
        raise $!
      end
    end
    def compose_highlighter anElement
      highlights = anElement.css('regexpHighlight')
      return highlights[1..-1].inject(make_highlighter(highlights[0])) do |result, e|
        make_highlighter(e).input(result)
      end
    end
    def make_highlighter anElement
      RegexpHighlighter.regexp(Regexp.new(anElement['regexp'])).
        span(anElement['class'])
    end
  end
end
