
maker = Mfweb::InfoDeck::DeckMaker.new('decks/infodeck/deck.xml', 
                                       BUILD_DIR + 'infodeck')
maker.lede_font_file = 'decks/IndieFlower.svg'
maker.mfweb_dir = "../"
maker.asset_server =
  Mfweb::InfoDeck::AssetServer.new('.', 
                                   MFWEB_DIR + 'lib/mfweb/infodeck')
maker.css_paths = [".",  MFWEB_DIR + 'lib/mfweb/infodeck',  
                   MFWEB_DIR + "css"]

maker.google_analytics_file = nil

infodeck_task maker
