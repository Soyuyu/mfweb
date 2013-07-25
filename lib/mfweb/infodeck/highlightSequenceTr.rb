module Mfweb::InfoDeck

class HighlightSequenceTransformer < DeckTransformer
  def initialize out_emitter, in_root, maker, builds
    super out_emitter, in_root, maker
    @builds = builds
  end
  def handle_highlight_sequence anElement
    steps = anElement.css('step').map{|e| e['name']}
    args = ([slide_id(anElement)] + steps).map{|e| e.inspect}.join(",")
    name = js_id(anElement['name'])
    @maker.js << "\n/* highlight sequence for #{name} */\n"
    @maker.js << "window.#{name} = new HighlightSequence(#{args});\n"
    apply anElement
    @maker.js << "\n\n"
  end
  def handle_step anElement
    tile_class = "highlight-description " + anElement['name']
    build = Build.new
    @builds << build
    @maker.js << step_build_assignment(anElement)
    name = js_id(slide_id(anElement) + '_' + anElement['name'])
    build.js_builder(name)
    emit_step_css anElement
    @html.div(tile_class + " tile") {apply anElement}
  end
  def step_build_assignment anElement
    sequence_name = js_id(anElement.ancestors('highlight-sequence')[0]['name'])
    step_name = js_id(anElement['name'])
    if anElement == anElement.parent.css('step')[0]
      result = []
      result << "window.%s_%s = {" % [js_id(slide_id(anElement)), step_name]
      result << "forwards:  function() {return #{sequence_name}.fadeIn();},"
      result << "backwards: function() {return #{sequence_name}.fadeOut();},"
      result << "setup_forwards: function() {return #{sequence_name}.setupAtStart();},"
      result << "setup_backwards: function() {return #{sequence_name}.setupAtEnd().show();}"
      result << "};\n"
      return result.join("\n")
    else
      "window.%s_%s = %s;\n" % [js_id(slide_id(anElement)), step_name, sequence_name]
    end
  end
  def emit_step_css anElement
    return if lacks_position?(anElement)
    selector = "#deck-container #%s .highlight-panel.%s" % 
      [slide_id(anElement), anElement['name']]
    emit_css_position_block anElement, selector
  end
  def handle_panel anElement
    selector = "#deck-container #%s .highlight-panel" % slide_id(anElement)
    emit_css_position_block anElement, selector
  end
  def emit_css_position_block anElement, selector
    @maker.put_css selector + " {\n"
    %w[top bottom left right width height].each {|a| emit_css_position anElement, a }
    @maker.put_css "}\n"
  end
  def emit_css_position anElement, attribute
    @maker.put_css "#{attribute}: #{anElement[attribute]}px;\n" if anElement[attribute]
  end
  def handle_description anElement
    selector = "#deck-container #%s .highlight-description" % slide_id(anElement)
    emit_css_position_block anElement, selector
  end
  def handle_build anElement
    bt = BuildTransformer.new(@html, anElement, @maker)
    bt.render
    @builds.last.merge! bt.build
  end
end

end
