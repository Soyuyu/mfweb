require 'minitest/unit'
require 'stringio'
require 'mfweb/infodeck'
require './test/infodeck/testSupport'

module Mfweb::InfoDeck

  class ArrowTransformerTester < Minitest::Test

    def transform aString
      @emitter = Mfweb::Core::HtmlEmitter.new
      @btr = DeckTransformer.new @emitter, Nokogiri::XML(aString).root, @maker
      @btr.render      
      @html = Nokogiri::XML(@emitter.out)    
    end

    def test_straight_arrow
      transform %{<arrow from = "300 300" to = "100 100" />}
      expected = %{
<svg class = 'arrow' height = '40px' style = '-moz-transform: rotate(-2.36rad);-moz-transform-origin: 0 50%;-ms-transform: rotate(-2.36rad);-ms-transform-origin: 0 50%;-o-transform: rotate(-2.36rad);-o-transform-origin: 0 50%;-webkit-transform: rotate(-2.36rad);-webkit-transform-origin: 0 50%;left: 300px;top: 280px;transform: rotate(-2.36rad);transform-origin: 0 50%;' width = '282px'>
<path d = 'M 0.00,20.00 L 280.84,20.00'></path>

<path d = 'M 280.84,20.00 m -20 -12 l 20 12 l -20 12'></path>
</svg>
}

      assert_equal expected, @emitter.out
    end
    def test_left_curve_arrow
      transform %{<arrow from = "300 300" to = "100 100" curve = "left"/>}
      expected = %{
<svg class = 'arrow' height = '112px' style = '-moz-transform: rotate(-2.36rad);-moz-transform-origin: 0 50%;-ms-transform: rotate(-2.36rad);-ms-transform-origin: 0 50%;-o-transform: rotate(-2.36rad);-o-transform-origin: 0 50%;-webkit-transform: rotate(-2.36rad);-webkit-transform-origin: 0 50%;left: 300px;top: 243.8314575050762px;transform: rotate(-2.36rad);transform-origin: 0 50%;' width = '282px'>
<path d = 'M 0.00,56.17 Q 140.42,0.00, 280.84,56.17'></path>

<path d = 'M 280.84,56.17 m -20 -12 l 20 12 l -20 12' transform = 'rotate(18, 280.84,56.17)'></path>
</svg>
}

      assert_equal expected, @emitter.out
    end
    def test_right_curve_arrow
      transform %{<arrow from = "300 300" to = "100 100" curve = "right"/>}
      expected = %{
<svg class = 'arrow' height = '112px' style = '-moz-transform: rotate(-2.36rad);-moz-transform-origin: 0 50%;-ms-transform: rotate(-2.36rad);-ms-transform-origin: 0 50%;-o-transform: rotate(-2.36rad);-o-transform-origin: 0 50%;-webkit-transform: rotate(-2.36rad);-webkit-transform-origin: 0 50%;left: 300px;top: 243.8314575050762px;transform: rotate(-2.36rad);transform-origin: 0 50%;' width = '282px'>
<path d = 'M 0.00,56.17 Q 140.42,112.34, 280.84,56.17'></path>

<path d = 'M 280.84,56.17 m -20 -12 l 20 12 l -20 12' transform = 'rotate(-18, 280.84,56.17)'></path>
</svg>
}

      assert_equal expected, @emitter.out
    end
  end
end
