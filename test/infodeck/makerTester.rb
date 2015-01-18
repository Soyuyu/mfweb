require 'minitest/autorun'
require 'stringio'


require 'infodeck'

module Mfweb::InfoDeck

  class MakerTester < Minitest::Test
    include InfoDeck

    BUILD_DIR = 'build/test/'

    def run_test_maker
      flunk "Unable to find Sass::Engine, run tests with bundle exec" unless defined? Sass::Engine
      mkdir_p BUILD_DIR, :verbose => false
      Site.init(TestSite.new)
      maker = DeckMaker.new('test/infodeck/makertest/deck.xml', BUILD_DIR)
      maker.asset_server = AssetServer.new("lib/mfweb/infodeck")
      maker.google_analytics_file = nil
      maker.mfweb_dir = "./"
      maker.css_paths += %w[sample/css]
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
      refute_nil  @included.at_css('#included-slide')
    end
  end

  class TestSite < Mfweb::Core::Site
    def load_skeleton
      @skeleton = Mfweb::Core::PageSkeleton.new nil, nil, []
    end
  end

end
