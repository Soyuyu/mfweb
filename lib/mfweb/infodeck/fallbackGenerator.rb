module Mfweb::InfoDeck
  class FallbackHeaderTransformer < Mfweb::Core::Transformer
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
      @root.css('abstract').each {|e| handle e}
      @root.css("author").each {|e| handle e}
      handle(@root.at_css("pub-date"))
      @html.div('notice') {@html << afterword}
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

  class FallbackDumpTransformer < Mfweb::Core::Transformer
    include Mfweb::InfoDeck

    def initialize out_emitter, in_root, maker
      super(out_emitter, in_root)
      @maker = maker
      # @apply_set = %w[deck tile lede author pub-date span build 
      #                 immediate-build show amazon br quote highlight-sequence 
      #                 h insertCode step b i]
      @copy_set = %w[a p ul li code table tr th td]
      @ignore_set = %w[partial img include diagram hide js-builder 
                       add-class linkMark char remove-class list-tags ]
      @p_set = {'abstract' => 'p'}
    end 
    
    def default_handler anElement
      # puts "unknown element #{anElement.name}"
      super
    end

    def handle_slide anElement
      @html.hr
      apply anElement
    end
   end





end

