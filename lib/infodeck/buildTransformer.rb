module InfoDeck
  class BuildTransformer < DeckTransformer
    attr_reader :build
    def initialize *args
      super *args
      @build = Build.new
    end
    def handle_build anElement
      apply anElement
    end
    def handle_show anElement
      selector = selector(anElement) || "." + anElement['class']
      @build.remove_class( selector, 'hidden')
      apply anElement
    end
    def handle_hide anElement
      @build.add_class( selector(anElement), 'hidden')
    end
    def handle_char anElement
      @build.add_class( selector(anElement), 'charred')
    end
    def handle_add_class anElement
      @build.add_class( selector(anElement), anElement['class'])
    end
    def handle_remove_class anElement
      @build.remove_class( selector(anElement), anElement['class'])
    end
    def selector anElement
      anElement['selector']
    end
    def handle_immediate_build anElement
      apply anElement
    end
    def handle_js_builder anElement
      @build.js_builder(anElement['target'])
    end
  end
end
