module Mfweb::InfoDeck
  class ArrowTransformer < DeckTransformer

    def self.new html, anElement, maker
      result = anElement['curve'] ? CurvedArrowTransformer.allocate : self.allocate
      result.send :initialize, html, anElement, maker
      return result
    end
    
    def handle_arrow anElement
      assert_valid_element
      svg_attrs, svg_style = {}, {}
      svg_attrs['width'] = "%dpx" % [svg_length]
      svg_attrs['height'] = "%dpx" % [svg_height]
      svg_attrs['class'] = 'arrow'
      svg_style['left'] = "%spx" % from_x
      svg_style['top'] = "%spx" % (from_y - svg_h_space)
      svg_style['transform-origin'] = "0 50%"
      svg_style['transform'] = "rotate(%1.2frad)" % path_angle
      populate_browser_prefixes svg_style, 'transform-origin', 'transform'
      add_to_style(svg_attrs, svg_style)
      @html.element("svg", svg_attrs) do
        @html.element("path", d: line_path)
        emit_arrow_head
      end
    end
    def populate_browser_prefixes(attrs, *keys)
      keys.each do |k|
        %w[ms webkit moz o].each do |prefix|
          attrs["-%s-%s" % [prefix, k]] = attrs[k]
        end
      end
    end
    def emit_arrow_head
      @html.element("path", d: arrow_head_path)
    end

    def assert_valid_element
      point_regex = %r{^\d+\s+\d+$}
      if point_regex !~ @root['from']
        raise "from is ill formatted <%s>" % @root['from']
      end
      if point_regex !~ @root['to']
        raise "to is ill formatted <%s>" % @root['to']
      end
    end

    def from_x
      @root['from'].split[0].to_i
    end
    def from_y
      @root['from'].split[1].to_i
    end
    def to_x
      @root['to'].split[0].to_i
    end
    def to_y
      @root['to'].split[1].to_i
    end   
    def head_dx
      20
    end
    def arrow_tip_offset 
      2
    end
    def path_dx 
      to_x - from_x
    end
    def path_dy 
      to_y - from_y
    end
    def head_dy
      head_dx * 0.6
    end
    def svg_h_space
      head_dx
    end
    def svg_length 
      Math.sqrt((path_dx ** 2) + (path_dy ** 2))
    end
    def svg_height 
      svg_h_space * 2
    end
    def path_length 
      svg_length - arrow_tip_offset
    end
    def path_angle 
      Math.atan2(path_dy, path_dx)
    end
    def start_point 
      Point.new(0,svg_h_space)
    end
    def end_point 
      Point.new(path_length, start_point.y)
    end
    def line_path 
      "M %s L %s" % [start_point, end_point]
    end
    def arrow_head_path 
      "M %s m %d %d l %d %d l %d %d" % 
        [end_point, -head_dx, -head_dy, head_dx, head_dy, -head_dx, head_dy]
    end
  end

  class CurvedArrowTransformer < ArrowTransformer
    def line_path 
      "M %s Q %s, %s" % [start_point, control_point, end_point]
    end
    def curve
      case @root['curve'] 
      when 'left' then -0.2
      when 'right' then 0.2
      else "value <%s> unknown for curve" % @root['curve']
      end
    end
    def control_offset 
     path_length * curve
    end
    def control_point 
      Point.new(path_length/2.0, start_point.y + control_offset)
    end
    def svg_h_space
      [head_dx, control_offset.abs].max
    end
    def emit_arrow_head
      attrs =  {d: arrow_head_path, 
        transform: ("rotate(%d, %s)" % [arrow_angle, end_point]), }
      @html.element("path", attrs)
    end
    def arrow_angle
       90 * -curve # derived by trail and error
    end
    def degrees radians_value
      radians_value * 180 / Math::PI
    end
   
  end

  class Point
    def initialize x,y
      @x = x
      @y = y
    end
    attr_reader :x, :y
    def to_s
      "%1.2f,%1.2f" % [x,y]
    end
    def - arg
      Point.new(x - arg.x, y - arg.y)
    end
  end
end
