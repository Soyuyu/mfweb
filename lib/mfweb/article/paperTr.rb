# -*- coding: utf-8 -*-
module Mfweb::Article

module PhotoHandlers
  def handle_photo anElement
    width = anElement['width'] 
    layout_class = case anElement['layout'] 
                   when "full" then "fullPhoto"
                   when "right" then "photo"
                   when nil then "photo"
                   else raise "unknown photo layout: " + anElement
                   end
    css_class = [layout_class, anElement['class']].join(" ")
    div_attrs = {class: css_class}
    div_attrs[:style] = "width: #{width}px;" if width
    @html.element('div', div_attrs) do
      #also put width here for RSS display
      img_attrs = {:src => img_dir(anElement['src'])}
      img_attrs[:title] = anElement['title'] if anElement['title']
      img_attrs[:width] = width if width
      @html.element('img', img_attrs){}
      render_photo_credit anElement
      @html.p('photoCaption') {apply anElement}
    end
    @html.div('clear') if "full" == anElement['layout']
  end
  def render_photo_credit anElement
    if anElement['credit']
      @html.p('credit') do
        @html << "photo: " + anElement['credit']
      end
    end
  end
  def img_dir src
    @maker ? @maker.img_out_dir(src) : src
  end
end


class PaperTransformer < Mfweb::Core::Transformer
  include Mfweb::Core::HtmlUtils
  include Mfweb::Core::XpathFunctions
  include PhotoHandlers

  def initialize output, root, maker
    raise 'heck' unless output
    super output, root, maker
    @copy_set = %w[b i p ul li a code table tr th td div ol span]
    @ignore_set = %w[footnote-list bibliography title subtitle
                     abstract meta-description meta-image]
    @apply_set = %w[sample]
    @section_depth = 1
    @has_printed_version = false
  end

  def handle_paper anElement
    @figureReader = FigureReader.new anElement
    print_front_matter
    apply anElement
    render_revision_history
  end

  def title_bar_text
    return @root.at_xpath('/paper/title').text
  end

  def front_matter_transformer
    "short" == @root['style'] ? ShortFrontMatterTransformer : FrontMatterTransformer
  end

  def print_front_matter    
    front_matter_transformer.new(@html, @root, @maker).handle(@root)
  end
  def handle_topImage anElement; end

  def render_revision_history
    return if "short" == @root['style']
    @html.div('appendix') do
      @html.h(2) do 
        @html.a_name 'SignificantRevisions'
        @html.text "Significant Revisions"
      end
      xpath("version").each do |v|
        @html.p do
          date = v['date']
          @html.i {@html.text "#{print_date date}: "}
          apply v
        end
      end
    end
  end

  def print_date aDateString
   return (/^\D+\s+\d+$/ =~ aDateString) ? 
    aDateString : # if like "July 2001"
      Date.parse(aDateString).strftime("%d %B %Y")
  end

  def footnote_server
    unless @footnote_server
      if @maker.respond_to? :footnote_server
        @footnote_server = @maker.footnote_server
      else 
        @footnote_server = FootnoteServer.new
        @footnote_server.load_doc(@root)
      end
    end
    @footnote_server
  end

  def draft?
    @maker.draft?
  end
  def handle_credits anElementl; end
  def handle_version anElement
    # ignore - printed during handling of abstract
  end
  def handle_translation anElement
    #ignore - printed during handling of abstract
  end
  def handle_contents anElement; end
  def default_handler anElement
    raise "unhandled case: " + anElement.name
    puts 'unhandled: ' + anElement.name
  end
  def handle_section anElement
    @section_depth += 1
    attrs = {:id => anchor_for(anElement)}
    @html.div(nil, attrs) do
      @html.hr('topSection') if @section_depth == 2
      apply anElement
    end
    @section_depth -= 1
  end
  def handle_H anElement
    @html.h(@section_depth) {apply anElement}
  end
  alias :handle_h :handle_H
  def handle_topBox anElement;  end


  def handle_body anElement
    attrs = {'class' => 'bodySep'}
    @html.div('paperBody') do
      apply anElement
      @html.element('hr', attrs){}
      @maker.render_end_box if @maker.respond_to?(:render_end_box)
    end
  end
  def handle_appendix anElement
    @html.div('appendix') {apply anElement}
  end
  def section_title aSectionElement
    flatten_content aSectionElement.at_xpath('H|h')
  end
  def flatten_content anElement
    buffer = StringIO.new
    fakeRenderer = Mfweb::Core::HtmlEmitter.new(buffer)
    trueRenderer = @html
    @html = fakeRenderer
    apply anElement
    @html = trueRenderer
    return strip_tags(buffer.string.strip)
   end
  def strip_tags aString
    #can't handle loose > in content
    aString.gsub(/<\/?[^>]*>/, "")
  end
  def anchor_for anElement
    case
    when anElement['ID'] then anElement['ID']
    when anElement['id'] then anElement['id']
    when not(section_title(anElement).empty?)
      section_title(anElement).to_anchor
    else nil
    end
  end
  def handle_cite anElement   
    bibref = @maker.bib_server[anElement['name']]
    if anElement.children.empty?
      bibref.link_around(@html, anElement)
    else
      bibref.link_around(@html) {apply anElement}
    end
  end
  def handle_patternRef anElement
    key = anElement['name']
    pattern = @maker.pattern_server.find key
    name = pattern.name
    name += "s" if "plural" == anElement['mode']
    if pattern.missing?
      @html.error pattern.message
    else
      @html.a_ref(pattern.url){@html.text name}
    end     
  end
  def handle_refactoring anElement
    r = @maker.refactoring_server.find(anElement['key'])
    @html.a_ref(r.url) {@html.text r.name}
  end
  def handle_blikiRef anElement
    name = anElement['name']
    href = "/bliki/#{name}.html"
    if anElement.children.empty?
      text = name.gsub(/[A-Z]/, ' \&').strip
      text += 's' if 'plural' == anElement['mode'] 
      @html.a_ref(href){@html.text text}
    else
      @html.a_ref(href){apply anElement}
    end
  end
  def handle_sidebar anElement
    attrs = {}
    attrs[:id] = anchor_for(anElement) if anchor_for(anElement)
    @html.div(form_css(anElement, 'sidebar'), attrs) {apply anElement}
  end
  def handle_soundbite anElement
    @html.div(form_css(anElement, 'soundbite')) do
      @html.p {apply anElement}
    end
  end
  def handle_img anElement
    attrs = attribute_hash anElement
    attrs['src'] = @maker.img_out_dir(anElement['src'])
    @html.element('img', attrs)
  end
  def handle_figure anElement
    css = form_css(anElement, 'figure')
    @html.div(css) do
      if anElement['align']
        puts "can't handle alignment attribute in figure yet"
      end
      src = anElement['src']
      fig_num = @figureReader.number(src)
      @html.p('figureImage')do
        @html.element('a', 'name' => a_name(src)) {}
        img_attrs = copy_some_attributes(anElement, :width => :width)
        img_style = {}
        img_style['max-width'] = 'none' if img_attrs.has_key?(:width)      
        img_attrs['alt'] = "Figure #{fig_num}"
        img_attrs['style'] = style_string(img_style)
        img_attrs['src'] = @maker.img_out_dir(src)
        @html.element('img', img_attrs) {}
      end
      unless anElement.children.empty?
        @html.p('figureCaption') do 
          @html.text "Figure #{fig_num}: "
          apply anElement
        end
      end
    end
  end
  def a_name aString
    return aString.gsub("/", "_")
  end
  def handle_book anElement
   @html.amazon(anElement['isbn']){apply anElement}
  end
  def handle_todo anElement
    handle_tbd anElement
  end
  def handle_tbd anElement
    return if %w[never later].include? anElement['when']
    if draft?
      emitTbd anElement
    else
      log.warn "TBD: #{anElement.text}"
    end
  end
  def emitTbd anElement
    if %w[section body].include? anElement.parent.name
      @html.p {emitTbdSpan anElement}
    else
      emitTbdSpan anElement
    end
  end
  def emitTbdSpan anElement
    @html.span('todo') do
      @html.text "[TODO: #{anElement.text}]"
    end
  end
  def handle_term anElement
    @html.b{apply anElement}
  end
  def handle_figureRef anElement
    apply anElement
    ref = anElement['ref']
    ref_text = ' Figure ' + @figureReader.number(ref)
    @html.a_ref('#' + a_name(ref)) {@html.text ref_text}
  end 
  def handle_pre anElement
    attrs = {}
    attrs['class'] = anElement['class'] if anElement['class']
    @html.element('pre', attrs) {apply anElement}
  end

  def handle_insertCode anElement
    @maker.code_server.render_insertCode anElement, @html, tr: self
  end

  def handle_author anElement
    #skip
  end 

  def handle_xref anElement
    href = ""
    file = anElement['file']
    href = file.sub('.xml', '.html') if file
    id = anElement['targetID']
    href << "#" + id if id
      
    @html.a_ref(href) {apply anElement}
  end
  def handle_xref_target anElement
    @html.a_name anElement['ID']
  end
  def handle_quote anElement
    attrs = copy_some_attributes anElement, 'class' => 'class'
    add_class attrs, 'aside' if 'aside' == anElement['position']
    @html.element('blockquote', attrs) do
      apply anElement
      @html.p('quote-attribution') do
        emit_quote_attribution anElement
      end
    end
  end
  def emit_quote_attribution anElement
    bibref = @maker.bib_server[anElement['ref']] if anElement['ref']
    credit = anElement['credit'] || anElement['source'] || (bibref && bibref.cite)
    # HACKTAG use of source attr comes from bliki
    return unless credit
    text = lambda {@html.text "-- " + credit}
    case
    when anElement.has_attribute?('href') then 
      @html.a_ref(anElement['href'], &text)
    when anElement.has_attribute?('url') then 
      @html.a_ref(anElement['url'], &text)
    when anElement.has_attribute?('isbn') then
      @html.amazon(anElement['isbn'], &text)
    when bibref 
      bibref.link_around(@html, &text)
    else text.call
    end
  end

  def handle_amazon anElement
   @html.amazon(anElement['key']){apply anElement}
  end    

  def handle_br anElement
    #needs special handling as <br></br> renders differently
    @html << "<br/>"
  end

  def handle_footRef anElement
    key = anElement['key']
    
    footnote_server.record key
    @html << footnote_server.render_reference(key)
  end

  def handle_display_footnotes anElement
    return if @root.css('footnote').empty?
    @html.div('footnote-list') do
      @html.h(2){@html << "Footnotes"}
      footnote_server.references.each do |key|
        render_footnote key
      end
    end
  end

  def render_footnote key 
    @html.element('div', 
                 :class => 'footnote-list-item', 
                 :id => footnote_server.anchor(key)) do
      head =  footnote_server.head(key)
      if head
        render_footnote_head key
        render_footnote_body key
      else 
        render_footnote_text key
      end
    end
  end

  def render_footnote_head key
    @html.element('h3', :class => 'head-text') do
      @html << "#{footnote_server.marker(key)}: "
      head =  footnote_server.head(key)
      @html << head.text 
    end
  end

  def render_footnote_body key
    footnote_server.body(key).each {|e| handle e}
  end
  
  def render_footnote_text key
    @html.p do
      @html.span('num') {@html << "#{footnote_server.marker(key)}: "}
      render_footnote_body key
      #@html << footnote_server.body(key)
    end
  end

  def handle_tweet anElement
    div_class = form_css(anElement, 'tweet')
    div_class += " tweet-sidebar" if "sidebar" == anElement['position'] 
    @html.div(div_class) do
      @html.element('blockquote',
                    class: 'twitter-tweet', lang: 'en',
                    'data-cards' => 'hidden') do
        apply anElement
        credit = "-- " + (anElement['credit'] || anElement['url'])
        @html.a_ref(anElement['url']){@html.text credit}
      end
      @html << '<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>'
    end
  end

  def handle_p_sub anElement
    @html.p('p-sub') {apply anElement}
  end

  def handle_future_installment anElement
    @html.div('next-installment') {
      @html.p {apply(anElement.at_css('installment-description'))}
    }
  end

  def handle_installment_target anElement
    @html.element('div', id: anElement['id'], class: 'installment-target') {apply anElement}
  end
end

class FigureReader
  include Mfweb::Core::XpathFunctions
  def initialize rootElement
    @root = rootElement
    @figures = load_figures @root
  end
  def load_figures anElement
    figure_elements = xpath('//figure', anElement)
    return figure_elements.collect {|e| e['src']}
  end 
  def number srcString
    index = (@figures.index(srcString))
    if index
      return (index + 1).to_s
    else
      puts "no figure for #{srcString}"
      return "?"
    end
  end
end

end
