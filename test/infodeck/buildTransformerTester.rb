require 'test/unit'
require 'stringio'
require 'mfweb/core'
require 'infodeck/deckTransformer'
require 'test/infodeck/testSupport'
require 'infodeck/buildTransformer'

module InfoDeck

  class BuildTransformerTester < Test::Unit::TestCase
    include TestTransform

    def transform aString
      @emitter = Mfweb::Core::HtmlEmitter.new
      Dir.chdir(TEST_DIR) do
        @maker = MakerStub.new
        @btr = BuildTransformer.new @emitter, Nokogiri::XML(aString).root, @maker
        @btr.render
      end
      @html = Nokogiri::XML(@emitter.out)    
    end

    #------- show --------------------------------

    def test_show_forwards
      transform "<show selector = '.sel'/>"
      assert_equal 1, @btr.build.elements.size
      assert_equal("$('# .sel').removeClass('hidden');",
                   @btr.build.elements[0].forwards_js)
    end
    def test_show_backwards
      transform "<show selector = '.sel'/>"
      assert_equal("$('# .sel').addClass('hidden');",
                   @btr.build.elements[0].backwards_js)
    end
    def test_show_setup_forwards
      transform "<show selector = '.sel'/>"
      assert_equal("$('# .sel').addClass('hidden');",
                   @btr.build.elements[0].setup_forwards_js)
    end
    def test_show_setup_backwards
      transform "<show selector = '.sel'/>"
      assert_equal("$('# .sel').removeClass('hidden');",
                   @btr.build.elements[0].setup_backwards_js)
    end


    #------- hide --------------------------------

    def test_hide_forwards
      transform "<hide selector = '.sel'/>"
      assert_equal 1, @btr.build.elements.size
      assert_equal("$('# .sel').addClass('hidden');",
                   @btr.build.elements[0].forwards_js)
    end
    def test_hide_backwards
      transform "<hide selector = '.sel'/>"
      assert_equal("$('# .sel').removeClass('hidden');",
                   @btr.build.elements[0].backwards_js)
    end
    def test_hide_setup_forwards
      transform "<hide selector = '.sel'/>"
      assert_equal("$('# .sel').removeClass('hidden');",
                   @btr.build.elements[0].setup_forwards_js)
    end
    def test_hide_setup_backwards
      transform "<hide selector = '.sel'/>"
      assert_equal("$('# .sel').addClass('hidden');",
                   @btr.build.elements[0].setup_backwards_js)
    end

    #------- char --------------------------------

    def test_char_forwards
      transform "<char selector = '.sel'/>"
      assert_equal 1, @btr.build.elements.size
      assert_equal("$('# .sel').addClass('charred');",
                   @btr.build.elements[0].forwards_js)
    end
    def test_char_backwards
      transform "<char selector = '.sel'/>"
      assert_equal("$('# .sel').removeClass('charred');",
                   @btr.build.elements[0].backwards_js)
    end
    def test_char_setup_forwards
      transform "<char selector = '.sel'/>"
      assert_equal("$('# .sel').removeClass('charred');",
                   @btr.build.elements[0].setup_forwards_js)
    end
    def test_char_setup_backwards
      transform "<char selector = '.sel'/>"
      assert_equal("$('# .sel').addClass('charred');",
                   @btr.build.elements[0].setup_backwards_js)
    end

    #------- js_builder --------------------------------

    def test_js_builder_forwards
      transform "<js-builder target = 'foo'/>"
      assert_equal 1, @btr.build.elements.size
      assert_equal("window.foo.forwards();",
                   @btr.build.elements[0].forwards_js)
    end
    def test_js_builder_backwards
      transform "<js-builder target = 'foo'/>"
      assert_equal("window.foo.backwards();",
                   @btr.build.elements[0].backwards_js)
    end
    def test_js_builder_setup_forwards
      transform "<js-builder target = 'foo'/>"
      assert_equal("window.foo.setup_forwards();",
                   @btr.build.elements[0].setup_forwards_js)
    end
    def test_js_builder_setup_backwards
      transform "<js-builder target = 'foo'/>"
      assert_equal("window.foo.setup_backwards();",
                   @btr.build.elements[0].setup_backwards_js)
    end

    #-----  other tests ----------------
    def test_children_of_show_emitted_with_class
      #TODO replace use of ref with class on all <show>s
      transform "<show class = 'sel'><tile/></show>"
      assert_not_nil @html.at_css('div.tile'), "no tile under show"
      assert_not_nil @html.at_css('div.sel'), "no sel under show"
    end
    def test_children_ledes_of_show_emitted_with_class
      transform "<show class = 'sel'><lede/></show>"
      assert_not_nil @html.at_css('div.lede'), "no block under show"
      assert_not_nil @html.at_css('div.sel'), "no sel under show"
    end
    def test_handle_immediate_build
      transform "<immediate_build><show selector = '.sel'/></immediate_build>"
      assert_equal 1, @btr.build.elements.size
      assert_equal("$('# .sel').removeClass('hidden');",
                   @btr.build.elements[0].forwards_js)
    end
  end
end
