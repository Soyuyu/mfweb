
#see <http://stackoverflow.com/questions/7742148/how-to-convert-text-to-svg-paths>

module Mfweb::InfoDeck
class SvgFont
  def self.load fileName
    return self.new(Nokogiri::XML(File.read(fileName)))
  end
  def initialize svg_doc
    raise "input is not Nokogiri" unless svg_doc.kind_of? Nokogiri::XML::Node
    raise "cannot see svg root in input" unless svg_doc.at_xpath("/svg") # see [^1]
    @svg_doc = svg_doc
    @glyph_cache = {}
  end
  def metadata
    @svg_doc.at_css('metadata')
  end
  def glyph char_str
    @glyph_cache[char_str] ||= extract_glyph char_str
    raise "no glyph for " + char_str unless @glyph_cache[char_str]
    return @glyph_cache[char_str]
  end
  def extract_glyph char_str
    if "'" == char_str 
      return @svg_doc.at_xpath("/svg/defs/font/glyph[@glyph-name = 'quotesingle']") 
    end
    @svg_doc.at_xpath("/svg/defs/font/glyph[@unicode = '#{char_str}']")
  end
  def path_for_char cstr
    glyph(cstr)['d']
  end
  def horiz_adv_x cstr
    glyph(cstr)['horiz-adv-x'].to_i
  end
  def svg aString, size, max_width, svg_attrs = {}
    size = determine_size size
    return FontPathProcessor.new(self, aString, size, max_width, svg_attrs).run   
  end
  def determine_size input
    default = 36.0
    case input
    when '' then default
    when nil then default
    when /^\d+$/ then input
    when /^(\d+)%$/ then $1.to_i * default / 100
    else raise "cannot parse font-size: <#{input}>"
    end
  end
  def units_per_em
    @svg_doc.at_css('font-face')['units-per-em'].to_f
  end
  # font height calcs are probably bad. I don't fully understand 
  # what's going on but am running with what seems to be working for the moment
  def line_height
    (ascent - descent)
  end
  def ascent
    @svg_doc.at_css('font-face')['ascent'].to_i
  end
  def descent
    @svg_doc.at_css('font-face')['descent'].to_i
  end

end

class FontPathProcessor
  def initialize svg_font, text, size, max_width, 
    svg_attrs = {}, result = StringIO.new
    @font = svg_font
    @text = text
    @size = size.to_f
    @x_offset = 0
    @y_offset = @font.ascent + @font.descent
    @result = result
    @svg_attrs = svg_attrs
    @xml = xml = Builder::XmlMarkup.new(:target=>@result, :indent=>2)
    @line_length = max_width.to_i / scale
    @max_line_width = 0
    @leading = @font.line_height * 0.2
    @has_run = false
  end
  def run
    raise "cannot run processor twice" if  @has_run
    @has_run = true
    transform = "scale(%s) translate(0, %s)" % [scale, @y_offset]
    attrs = @svg_attrs.merge(:transform => transform)
    @xml.g(attrs){render_block(split_to_lines(@text))}
    return self
  end
 def render_block lineArray
   lineArray.each do |line|
     render_line line
     @y_offset += @font.line_height + @leading
     @max_line_width = [@max_line_width, @x_offset].max
     @x_offset = 0
    end
  end
  def render_line wordArray
    line = wordArray.join(" ")
    line.each_char{|c| render_letter(c)}
  end
  def render_letter s
    transform = "translate(%s,%s) scale(1,-1)" % [@x_offset, @y_offset]
    @x_offset += @font.horiz_adv_x(s)
    return if " " == s
    element = "<path transform = '%s' d = '%s'/>" % [transform, @font.path_for_char(s)]
    @xml << element  # output via text rather than builder reduced time 10s -> 3s 
  end
  def split_to_lines text
    lines = []
    current_line = []
    lines << current_line
    text.split.each do |word|
      if text_width((current_line + [word]).join(" ")) > @line_length
        current_line = []
        lines << current_line
      end
      current_line << word
    end
    return lines
  end
  def text_width text
    text.each_char.inject(0){|res, c| res += @font.horiz_adv_x(c)}
  end
  def height
   scale * @y_offset  
  end
  def width
    scale * @max_line_width
  end
  def content
    @result.string
  end
  def scale 
    @size / @font.units_per_em
  end
end

class App
  def initialize
    @emit_html = false
  end
  def run out = $stdout
    out << "<html><body>" if @emit_html
    out << "<svg>"
    out << SvgFont.load(ARGV[0]).svg($stdin.read)
    out << "</svg>"
    out << "</body></html>" if @emit_html
  end
end

end

if __FILE__ == $0
  FontPath::App.new.run
end


# Notes
#
# [^1]: Looks like if you have an svg file with a namespace
# declaration such as `<svg xmlns="http://www.w3.org/2000/svg">` then
# this xpath will choke. I haven't dug into why, I just changed the
# xvg file to remove the namespace declaration
