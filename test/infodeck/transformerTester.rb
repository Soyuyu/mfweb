require 'test/unit'
require 'stringio'
require 'mfweb/infodeck'
require './test/infodeck/testSupport'

module Mfweb::InfoDeck

class DeckTransformerTester < Test::Unit::TestCase
  include TestTransform
  def style key, node
    style_str = node['style']
    return nil unless style_str
    result = /#{key}:\s*([\w.]+)/.match(style_str)[1]
  end
  def test_adds_default_position_to_lede_without_position
    transform "<slide><lede>f</lede><slide>"
    assert_match(/header-position/,  @html.at_css('div.lede')['class'])
  end
  def test_leaves_lede_position_data_alone
    transform "<slide><lede right = '10'>f</lede><slide>"
    assert_no_match(/top:/,  @html.at_css('svg')['style'])
  end
  def test_lede_position_data_copied_over
    transform "<slide><lede right = '10'>f</lede><slide>"
    assert_equal('left: auto;right: 10px;',  @html.at_css('div.lede')['style'].strip)
  end
  def test_use_svg_dimensions_from_svg_file
    transform_slide "<img src = 'native.svg'/>"

    html_svg = @html.at_css('svg')
    assert_equal "358.51483px", @html.at_css('img')['height']
    assert_equal "366.93069px", @html.at_css('img')['width']
  end
  def test_use_provided_svg_dimensions_if_there
    transform_slide "<img src = 'native.svg'  height = '15' width = '10'/>"
    html_svg = @html.at_css('svg')
    assert_equal "15px", @html.at_css('img')['height']
    assert_equal "10px", @html.at_css('img')['width']
  end
  def test_use_one_dimension_and_scale_the_other
    transform_slide "<img src = 'native.svg'  height = '15'/>"
    html_svg = @html.at_css('svg')
    assert_equal "15px", @html.at_css('img')['height']
    assert_equal "15.35px", @html.at_css('img')['width']
  end
  def test_position_heading_adds_heading_class
    transform_slide "<img src = 'native.svg' position = 'heading'/>"
    assert_match(/header-position/,  @html.at_css('img')['class'])
  end
  def test_position_injects_zero_left_if_right_present
    transform_slide "<tile right = '100'/>"
    assert_match(/right: 100px/,  @html.at_css('div.tile')['style'])
    assert_match(/left: auto/,  @html.at_css('div.tile')['style'])
  end
  def test_position_handles_auto_right
    transform_slide "<tile right = 'auto' left = '50'/>"
    assert_match(/right: auto/,  @html.at_css('div.tile')['style'])
    assert_match(/left: 50px/,  @html.at_css('div.tile')['style'])
  end
  def test_add_width_to_tile
    transform_slide("<tile width = '10em'/>")
    assert_match(/width: 10em/, @html.at_css('div.tile')['style'])
  end
  def test_lede_to_text
    transform_slide("<lede>Cross-Platform Toolkits</lede>")
    svg = @html.at_css('svg')
    assert_in_delta 57.6, svg['height'].to_f, 0.1
    assert_in_delta 342.252, svg['width'].to_f, 0.001
  end
  def test_transforms_img
    transform_slide("<img src = 'foo.jpg' width = '50' left = '20%'/>")
    assert_match(/left: 20%/, @html.at_css('img')['style'])
    assert_match(/foo.jpg/, @html.at_css('img')['src'])
    assert_match(/width: 50px/, @html.at_css('img')['style'])
  end
  def test_show_emits_children
    transform_slide "<build ref='notthis'><show class='b1'><tile width= '177'/></show></build>"
    assert_not_nil @html.at_css('div.tile'), "did not emit child of show"
    assert_match(/width: 177px/, @html.at_css('div.tile')['style'])  #checks get right element
  end
  def test_inject_ref_from_parent_show
    transform_slide "<build ref='notthis'><show class='b1'><tile width= '177'/></show></build>"
    assert_equal "tile b1",  @html.at_css('div.tile')['class']
  end
  def test_no_action_if_no_ref
    transform_slide "<tile/>"
    assert_equal "tile", @html.at_css('div.tile')['class']
  end
  def test_calculate_horizontal_center
    transform_slide "<tile width = '400' position = 'h-center'/>"
    assert_equal "280.00px", style('left', @html.at_css('div.tile'))
  end
  def test_inject_width_does_nothing_if_no_width
    transform_slide "<tile/>"
    assert_no_match /width/, @html.at_css('div.tile')['style']
  end

  def test_warn_if_font_in_svg_file_as_img
    output_log = StringIO.new
    capture_log(Logger.new(output_log)) do
      transform_slide "<img src = 'contains-marydale.svg'/>"
    end
    assert_equal 1, output_log.string.split("\n").size
  end
  def test_warn_if_font_in_svg_file_as_diagram
    output_log = StringIO.new
    capture_log(Logger.new(output_log)) do
      transform_slide "<diagram src = 'contains-marydale.svg'/>"
    end
  end
  def test_allow_named_font_in_svg_diagram
    output_log = StringIO.new
    capture_log(Logger.new(output_log)) do
      transform_slide "<diagram src = 'contains-inconsolata.svg'/>"
    end
    assert_equal 0, output_log.string.split("\n").size
  end
  def test_dont_allow_named_font_in_svg_img
    output_log = StringIO.new
    capture_log(Logger.new(output_log)) do
      transform_slide "<img src = 'contains-inconsolata.svg'/>"
    end
    assert_equal 1, output_log.string.split("\n").size
  end
  def test_lede_img
    transform_slide "<lede src = 'native.svg'>some text</lede>"
    assert_match /header-position/, @html.at_css('img.lede')['class']
  end
  def test_lede_img_with_position_data
    transform_slide "<lede src = 'native.svg' top = '50'>some text</lede>"
    assert_equal 'top: 50px;', @html.at_css('img.lede')['style'].strip
  end
  def test_lede_img_has_title
    transform_slide "<lede src = 'native.svg' top = '50'>some text</lede>"
    assert_equal 'some text', @html.at_css('img.lede')['title'].strip
  end
  def test_lede_with_svg_avoids_empty_style
    transform_slide "<lede src = 'native.svg'>some text</lede>"
    assert(!(@html.at_css('img.lede').has_attribute?('style')))
  end
end
end
