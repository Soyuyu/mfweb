require 'minitest/unit'
require 'stringio'
require 'mfweb/infodeck'
require './test/infodeck/testSupport'

module Mfweb::InfoDeck

  class ArrowTransformerTester < MiniTest::Unit::TestCase

    def transform aString
      @emitter = Mfweb::Core::HtmlEmitter.new
      @btr = ArrowTransformer.new @emitter, Nokogiri::XML(aString).root, @maker
      @btr.render      
      @html = Nokogiri::XML(@emitter.out)    
    end

    def test_basic_arrow
      transform %{<arrow from = "300 300" to = "100, 100" />}
      expected = %{
<svg class = 'arrow' height = '40px' style = '-moz-transform: rotate(-2.36rad);-moz-transform-origin: 0 50%;-ms-transform: rotate(-2.36rad);-ms-transform-origin: 0 50%;-o-transform: rotate(-2.36rad);-o-transform-origin: 0 50%;-webkit-transform: rotate(-2.36rad);-webkit-transform-origin: 0 50%;left: 300px;top: 280.0px;transform: rotate(-2.36rad);transform-origin: 0 50%;' width = '282px'>
<path d = 'M 0,20 l 280,0.000000 m -20,-12 l 20,12 l -20,12'></path>
</svg>
}


      assert_equal expected, @emitter.out
    end
  end
end
