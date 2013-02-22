module Mfweb::InfoDeck
  module TestTransform
    TEST_DIR = 'test/infodeck/'
    def transform input
      @emitter = Mfweb::Core::HtmlEmitter.new
      Dir.chdir(TEST_DIR) do
        @maker = MakerStub.new
        DeckTransformer.new(@emitter,Nokogiri::XML(input).root, @maker).render
      end
      @html = Nokogiri::XML(@emitter.out)    
    end
    def transform_slide input
      transform "<slide>%s</slide?" % input
    end
  def capture_log aLogger
    old_logger = $logger
    $logger = aLogger
    begin 
      yield
    ensure
      $logger = old_logger
    end
  end
  end

  class MakerStub
    attr_reader :lede_font
    def initialize
      @lede_font = Mfweb::InfoDeck::SvgFont.load('../../sample/decks/IndieFlower.svg')
    end
    def img_file file_name
      'img/' + file_name
    end
    def draft?; false; end
    def allowed_fonts
      ['Inconsolata']
    end

  end


end
