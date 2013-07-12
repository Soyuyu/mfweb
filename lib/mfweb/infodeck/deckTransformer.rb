# -*- coding: utf-8 -*-
module Mfweb::InfoDeck

class DeckTransformer < Mfweb::Core::Transformer
  include Mfweb::InfoDeck
  attr_reader :builds
  def initialize out_emitter, in_root, maker
    super(out_emitter, in_root)
    @maker = maker
    @apply_set = %w[deck]
    @copy_set = %w[ul li p b i a code table tr th td br]
    @p_set = {'h' => 'h2'}
    @builds = SlideBuildSet.new(@root['id'])
    @current_build = nil
   end
  def default_handler anElement
    raise "unknown element: " + anElement.name
  end

  def slide_id anElement
    anElement.ancestors("slide").first['id']
  end

  def add_class attrHash, class_name
    return unless class_name
    if attrHash.key? :class
      attrHash[:class] += " " + class_name
    else
      attrHash[:class] = class_name
    end
  end

  def handle_slide anElement
    attrs = copy_some_attributes(anElement, :id => 'id')
    add_class attrs, 'slide'
    add_class attrs, anElement['class']
    add_class attrs, 'anim-continue' if anElement.at_css('immediate-build')
    @html.element('div', attrs) do
      apply anElement
      emit_draft_marker if @maker.draft?
      emit_draft_notice if @maker.draft? && 'cover' == anElement['id']
    end
  end

  def emit_draft_marker
    @html.div('draft-marker') do
      @html.p {@html << "Draft Only"}
      @html.p {@html << "Do not share or link"}
    end
  end

  def emit_draft_notice
    @html.element('img', :src => 'draft-notice.svg', :class => 'draft-notice')
  end

  def handle_lede anElement
    emit_lede anElement, {}
  end

  def emit_lede anElement, attrs
    add_class attrs, 'lede'
    add_class attrs, 'header-position' if lacks_position? anElement
    inject_class attrs, anElement
    if anElement.key? 'src'
      attrs['src'] = anElement['src']
      attrs['title'] = anElement.text if anElement.has_text?
      emit_img anElement, attrs
    else
      inject_position attrs, anElement
      inject_width attrs, anElement
      @html.element('div', attrs) {@html.p {apply anElement}}
    end
  end

  def read_svg_doc file_name
    raise "Unable to find #{file_name} from #{Dir.pwd}" unless File.exists? file_name
    result = Nokogiri::XML(File.read(file_name)).at_css('svg')
    return result
  end

  def check_no_fonts_in_svg svg_doc, file_name, allowed_fonts = []
    log.warn "font present in svg file as img: %s" % file_name unless svg_doc.css('text').empty?  
  end

  def check_only_allowed_fonts_in_svg  svg_doc, file_name
    styles = svg_doc.css('text').map{|e| SvgManipulator.new(svg_doc).style(e)}
    unless styles.all?{|s|@maker.allowed_fonts.include?(s['font-family'])}
      log.warn "non-allowed font present in svg file: %s" % file_name 
    end
  end 

  def handle_diagram anElement
    emit_svg anElement, {:class => 'diagram'}
  end

  def emit_svg anElement, attrs
    svg_file = @maker.img_file(anElement['src'])
    raise "Unable to find #{svg_file} from #{Dir.pwd}" unless File.exists? svg_file
    svg_doc = read_svg_doc(svg_file)
    check_only_allowed_fonts_in_svg svg_doc, svg_file
    add_class attrs, anElement['class']
    inject_position attrs,  anElement
    inject_id attrs, anElement
    manipulate_svg anElement, svg_doc 
    attrs['viewbox'] = "0 0 %s %s" % [svg_doc['width'], svg_doc['height']]
    inject_svg_dimensions attrs, anElement, svg_doc    
    @html.element('svg', attrs) {@html << svg_doc.to_xml}
  end

  def inject_id attrs, anElement
    attrs['id'] = anElement['id'] if anElement.has_attribute? 'id'
  end

  def handle_use anElement
    @html.element('svg') do
      @html.element('use', 'xlink:href' => anElement['ref'])
    end
  end

  def manipulate_svg anElement, svg_doc
    return unless anElement['manipulator']
    Mfweb::InfoDeck.const_get(anElement['manipulator']).new(svg_doc).run
  end


  def inject_svg_dimensions attrHash, anElement, svg_doc
    height = anElement['height'] 
    width  = anElement['width']  
    if (!height and !width)
      width = svg_doc['width']
      height = svg_doc['height']
    elsif !(height and width)
      if height
        raise 'no width in svg' unless svg_doc['width']
        width  = height.to_i / svg_doc['height'].to_f * svg_doc['width'].to_f
      else
        raise 'no height in svg' unless svg_doc['height']
        height = width.to_i / svg_doc['width'].to_f * svg_doc['height'].to_f
      end
    end
    attrHash['height'] = add_units(height)
    attrHash['width'] = add_units(width)
  end

 def add_units aStringOrNumber
   if aStringOrNumber.kind_of? Numeric
     return "%.2fpx" % aStringOrNumber
   else     
     (/\d\s*$/ =~ aStringOrNumber) ? aStringOrNumber + 'px' : aStringOrNumber
   end
  end
  def handle_tile anElement
    emit_tile(anElement, {}) {apply anElement}
  end

  def emit_tile anElement, attrs
    add_class(attrs, 'tile')   
    add_class(attrs, anElement['style'])
    inject_position attrs, anElement
    inject_width attrs, anElement
    inject_class attrs, anElement
    @html.element('div',  attrs) {yield}
  end

  def inject_class attrs, anElement
    add_class attrs, anElement['class']
    show = anElement.ancestors('show').first
    add_class attrs, show['class'] if show
  end
  def inject_width attrs, anElement
    add_to_style(attrs, 'width' => add_units(anElement['width']))
  end

  def inject_class_from_show attrs, anElement
    ancestor_show = anElement.ancestors.detect{|e| 'show' == e.name}
    add_class(attrs, ancestor_show['class']) if ancestor_show
  end


  def add_to_style attrHash, values
    return unless values
    attrHash[:style] ||= ""
    keys = values.reject{|k,v| nil == v}.keys
    attrHash[:style] += keys.sort.inject("") do |res, k| 
      res += "%s: %s;" % [k, values[k]] 
    end
    attrHash.delete(:style) if attrHash[:style].empty?
    return attrHash
  end

  def inject_position attrHash, anElement
    case anElement['position']
    when 'heading' then
      add_class attrHash, 'header-position'
    when 'full' then
      add_class attrHash, 'full-slide'
    else
      pos = interpret_position_attribute anElement
      pos.merge! copy_source_boundaries anElement
      inject_style attrHash, pos, %w[left top right bottom]
    end
  end

  def interpret_position_attribute anElement
    h_center = {'left' => 480 - anElement['width'].to_i / 2}
    case anElement['position']
    when 'h-center'
      h_center
    else
      {}
    end
  end

  def copy_source_boundaries anElement
    raise "cannot set left and right: %s" % anElement if
      explicit_dimension(anElement['left']) and explicit_dimension(anElement['right'])
    result = %w[left right top bottom].inject({}) do |total, w| 
      total[w] = anElement[w] if anElement.key? w
      total
    end
    result['left'] = 'auto' if explicit_dimension result['right']
    return result
  end

  def explicit_dimension arg
    return arg && ('auto' != arg)
  end

  def inject_style attrs, elem, keys
    values = keys.inject({}) do |res, key| 
      res[key] = add_units(elem[key])
      res
    end
    add_to_style attrs, values
  end

  def form_style elem, keys
    keys.inject("") do |res, k|
      res +=  elem.key?(k) ? "%s: %s; " % [k, add_units(elem[k])] : ""
    end
  end

  def lacks_position? anElement
    (%w[left right top bottom] & anElement.keys).empty?
  end

  def handle_img anElement
    attrs = copy_some_attributes(anElement, {:src => :src, :style => :style})
    emit_img anElement, attrs
   end

  def emit_img anElement, attrs
    add_to_style(attrs, 'width' => add_units(anElement['width']))
    inject_class attrs, anElement
    inject_position attrs, anElement
    if %r{^[^/].*\.svg$} =~ anElement[:src]
      svg_file = @maker.img_file(anElement['src'])
      svg_doc = read_svg_doc(svg_file)
      inject_svg_dimensions attrs, anElement, svg_doc
      check_no_fonts_in_svg svg_doc, svg_file
    end
    case
    when anElement.has_attribute?('href') then
      @html.a_ref(anElement['href']){@html.element('img', attrs){}}
    when anElement.has_attribute?('asin') then
      @html.amazon(anElement['asin']){@html.element('img', attrs){}}
    else
      @html.element('img', attrs){}
    end
  end

  def handle_span anElement
    attrs = copy_some_attributes anElement, {'class' => :class}
    @html.element('span', attrs) {apply anElement}
  end

  def handle_todo anElement
    @html.span('todo') do
      @html.b {@html << "TODO: "}
      apply anElement
    end
    puts "WARNING: todos are present" unless @maker.draft?
  end


  def handle_partial anElement
    @maker.add_partial anElement['id'], anElement
  end

  def handle_include anElement
    if anElement.has_attribute?('class')
      @html.div(anElement['class']) {emit_partial anElement}
    else
      emit_partial anElement
    end
  end

  def emit_partial anElement
    apply(@maker.partial(anElement['ref']))
  end

  def handle_linkMark anElement
    attrs = {}
    anElement.attributes.each{|k,v| attrs[k] = anElement[k]}
    attrs['class'] = "link-mark"
    @html.element('a', attrs) {@html.text "†"}
  end

  def handle_amazon anElement
    @html.amazon(anElement['asin']){apply anElement}
  end

  def handle_insertCode anElement
    if anElement.children.empty?
      @maker.code_server.render_insertCode anElement, @html
    else
      RegexpHighlighterTransformer.new(@html, anElement, @maker).render
    end
  end
  def handle_quote anElement
    QuoteTransformer.new(@html, anElement, @maker).render
  end
  def handle_abstract anElement
    @html.p('abstract') {apply anElement}
  end
  def handle_pub_date anElement
    date_str =  DateTime.parse(anElement.text).strftime("%-d %B %Y")
    @html.span("pubDate") {@html.text date_str}
  end
  def handle_author anElement
    attrs = {href: anElement['href'], rel: 'author'}
    @html.element('a', attrs) {apply anElement}
  end
  def handle_title anElement
    html.span('title') {apply anElement}
  end
  def handle_build anElement
    bt = BuildTransformer.new(@html, anElement, @maker)
    bt.render
    @builds << bt.build
  end
  def handle_immediate_build anElement
    bt = BuildTransformer.new(@html, anElement, @maker)
    bt.render
    @builds.immediate = bt.build
  end
  def handle_highlight_sequence anElement
    tr = HighlightSequenceTransformer.new(@html, anElement, @maker, @builds)
    tr.render
  end
  def js_id aString
    aString.gsub('-', '_')
  end
  def slide_id anElement
    anElement.ancestors('slide')[0]['id']
  end
  def handle_arrow anElement
    ArrowTransformer.new(@html, anElement, @maker).render
  end
end

class QuoteTransformer < DeckTransformer
  def handle_quote anElement
    attrs = {}
    inject_position attrs, anElement
    inject_width attrs, anElement
    inject_class attrs, anElement
    @html.div('quote', attrs) do
      src =  anElement['photo'] || 'quote-icon.svg'
      @html.element('img', :src => src, :width => "50px")
      @html.p do
        @html.span('text') {apply anElement}
        @html.text "-- " 
        @html.span('name') {@html.text anElement['name']}
        if anElement['affiliation']
          @html.span('affiliation') {@html.text ", " + anElement['affiliation'] }
        end
      end
    end
  end  
end



end
