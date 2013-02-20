require 'test/unit'
require 'stringio'
require 'infodeck/maker'

module InfoDeck

  class MakerTester < Test::Unit::TestCase
    include InfoDeck

    BUILD_DIR = 'lib/test/build/'

    def run_test_maker
      mkdir_p BUILD_DIR, :verbose => false
      maker = DeckMaker.new('lib/test/infodeck/makertest/deck.xml', BUILD_DIR)
      maker.lede_font_file = 'decks/Marydale.svg'
      maker.run
      @result = Nokogiri::HTML(File.read(BUILD_DIR + '/index.html', encoding: 'utf-8'))
    end


    def test_title_comes_from_deck
      run_test_maker
      assert_equal 'This is the title', @result.at_css('title').text
    end

    def test_included_external_deck
      run_test_maker
      @included =  Nokogiri::HTML(File.read(BUILD_DIR + 'included-slide.html'))
      assert_not_nil  @included.at_css('#included-slide')
    end
  end

end
