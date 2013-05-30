require 'mfweb/infodeck/infodeck.rake'

maker = Mfweb::InfoDeck::DeckMaker.new('decks/infodeck/deck.xml', 
                                       BUILD_DIR + 'infodeck')
maker.mfweb_dir = MFWEB_DIR
maker.asset_server =
  Mfweb::InfoDeck::AssetServer.new('.', 
                                   MFWEB_DIR + 'lib/mfweb/infodeck')
maker.css_paths = [".",  'css', 
                   MFWEB_DIR + 'lib/mfweb/infodeck',  
                   MFWEB_DIR + "css"]

maker.google_analytics_file = nil

infodeck_task maker
