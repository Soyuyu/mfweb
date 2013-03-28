module Mfweb::InfoDeck
  class IndexTransformer < Mfweb::Core::Transformer
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
  end
end
