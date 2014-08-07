module TestVisualDeck
  class Maker <  Mfweb::InfoDeck::DeckMaker
    def import_local_ruby; end # got an error, couldn't figure out why
    def generate_fallback; end # don't need
    def transformer_class
      MyDeckTransfomer
    end
  end

  class MyDeckTransfomer < Mfweb::InfoDeck::DeckTransformer
  end

end

