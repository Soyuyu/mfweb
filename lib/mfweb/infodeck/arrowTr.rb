module Mfweb::InfoDeck
  class ArrowTransformer < DeckTransformer
    
    def handle_arrow anElement
      svg_attrs, svg_style = {}, {}
      svg_attrs['width'] = "%dpx" % [svg_length]
      svg_attrs['height'] = "%dpx" % [svg_height]
      svg_attrs['class'] = 'arrow'
      svg_style['left'] = "%spx" % from_x
      svg_style['top'] = "%spx" % (from_y - svg_height / 2.0)
      svg_style['transform-origin'] = "0 50%"
      svg_style['transform'] = "rotate(%1.2frad)" % path_angle
      populate_browser_prefixes svg_style, 'transform-origin', 'transform'
      add_to_style(svg_attrs, svg_style)
      @html.element("svg", svg_attrs) do
        path_attrs = {'d' => [line_path, arrow_head_path].join(" ")}
        @html.element("path", path_attrs)
      end
    end
    def populate_browser_prefixes(attrs, *keys)
      keys.each do |k|
        %w[ms webkit moz o].each do |prefix|
          attrs["-%s-%s" % [prefix, k]] = attrs[k]
        end
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
    def svg_length 
      Math.sqrt((path_dx ** 2) + (path_dy ** 2))
    end
    def svg_height 
      head_dx * 2
    end
    def path_length 
      svg_length - arrow_tip_offset
    end
    def path_angle 
      Math.atan2(path_dy, path_dx)
    end
    def start_point 
      "0,%d" % head_dx
    end
    def end_point 
      "%d,%f" % [path_length, 0]
    end
    def line_path 
      "M %s l %s" % [start_point, end_point]
    end
    def arrow_head_path 
      "m %d,%d l %d,%d l %d,%d" % 
        [-head_dx, -head_dy, head_dx, head_dy, -head_dx, head_dy]
    end
    
  end
end
