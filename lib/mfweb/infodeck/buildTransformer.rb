module Mfweb::InfoDeck
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
      @build.show(selector)
      apply anElement
    end
    def handle_hide anElement
      @build.hide(selector(anElement))
    end
    def handle_char anElement
      @build.char(selector(anElement))
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
