require 'test/unit'
require 'stringio'
require 'mfweb/core'
require 'mfweb/infodeck'
require './test/infodeck/testSupport'

module Mfweb::InfoDeck

  class HighlightSequenceTrTester < Test::Unit::TestCase
    include TestTransform

    def transform aString
      @emitter = Mfweb::Core::HtmlEmitter.new
      Dir.chdir(TEST_DIR) do
        @maker = MakerStub.new
        @root =  Nokogiri::XML(aString).root
        @builds = SlideBuildSet.new(@root['id'])
        @htr = HighlightSequenceTransformer.new(@emitter,@root, @maker, @builds)
        @htr.render
      end
      @html = Nokogiri::XML(@emitter.out)    
    end


    def test_highlight_sequence_with_build
      transform %{<slide id = "test"><highlight-sequence name = "test">
            <step name="second" left="220">
              <build><char selector = ".s2"/></build>
            </step></highlight-sequence></slide>}
      assert @builds.assert_ok 
    end
  end
end
