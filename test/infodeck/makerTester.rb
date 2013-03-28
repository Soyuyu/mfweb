require 'test/unit'
require 'stringio'
require 'infodeck/maker'

module Mfweb::InfoDeck

  class MakerTester < Test::Unit::TestCase
    include InfoDeck

    BUILD_DIR = 'lib/test/build/'

    def run_test_maker
      mkdir_p BUILD_DIR, :verbose => false
      maker = DeckMaker.new('test/infodeck/makertest/deck.xml', BUILD_DIR)
      maker.asset_server = AssetServer.new("lib/mfweb/infodeck")
      maker.lede_font_file = 'sample/decks/IndieFlower.svg'
      maker.google_analytics_file = nil
      maker.mfweb_dir = "./"
      maker.run
      @result = Nokogiri::HTML(File.read(BUILD_DIR + '/index.html', encoding: 'utf-8'))
    end


    def test_title_comes_from_deck
      run_test_maker
      assert_equal 'This is the title', @result.at_css('title').text
    end

    def test_included_external_deck
      Site.init(Site.new)
      run_test_maker
      @included =  Nokogiri::HTML(File.read(BUILD_DIR + 'included-slide.html'))
      assert_not_nil  @included.at_css('#included-slide')
    end
  end

end
