module Mfweb::InfoDeck
  class FallbackMaker
    def initialize base_maker
      @base_maker = base_maker
    end
  end
  class FallbackTransformer < Mfweb::Core::Transformer
    include Mfweb::InfoDeck
    def initialize out_emitter, in_root, maker
      super(out_emitter, in_root)
      @maker = maker
      @apply_set = %w[deck]
      @copy_set = %w[b a i]
      @ignore_set = %w[partial]
    end 
    def default_handler anElement
      raise "unknown element: " + anElement.name
    end
    def handle_deck anElement
      @html.h(1) {@html.text @root['title']}
      handle(@root.at_css('abstract'))
      @root.css("author").each {|e| handle e}
      handle(@root.at_css("pub-date"))
      @html << afterword
    end
    def handle_abstract anElement
      @html.p('abstract') {apply anElement}
    end
    def handle_pub_date anElement
      date_str =  DateTime.parse(anElement.text).strftime("%-d %B %Y")
      @html.p("pubDate") {@html.text date_str}
    end
    def handle_author anElement
      @html.p('author') do
        attrs = {href: anElement['href'], rel: 'author'}
        @html.element('a', attrs) {apply anElement}
      end
    end
    def afterword
      raw = File.read(@maker.asset('fallback.md'))
      text = ERB.new(raw).result(binding)
      Kramdown::Document.new(text).to_html
    end
    def link 
      "<a href = '#{@maker.uri}'>http://martinfowler.com#{@maker.uri}</a>"
    end
  end
end
