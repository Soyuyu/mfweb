# -*- coding: utf-8 -*-
module Mfweb::Article

module PhotoHandlers
  def handle_photo anElement
    width = anElement['width']
    css_class = case anElement['layout'] 
                  when "full" then "fullPhoto"
                  when "right" then "photo"
                  when nil then "photo"
                  else raise "unknown photo layout: " + anElement
                end
    @html.element('div', {:class => css_class, 
                    :style => "width: #{width}px;" }) do
      attrs = {:src => anElement['src'], title: anElement['title']}
      @html.element('img', attrs){}
      render_photo_credit anElement
      @html.p('photoCaption') {apply anElement}
    end
  end
  def render_photo_credit anElement
    if anElement['credit']
      @html.p('credit') do
        @html << "photo: " + anElement['credit']
      end
    end
  end
end


class PaperTransformer < Mfweb::Core::Transformer
  include Mfweb::Core::HtmlUtils
  include Mfweb::Core::XpathFunctions
  include PhotoHandlers

  def initialize output, root, maker
    raise 'heck' unless output
    super output, root
    @maker = maker
    @copy_set = %w[b i p ul li a code img table tr th td div ol]
    @ignore_set = %w[footnote-list bibliography title subtitle abstract]
    @apply_set = %w[sample]
    @section_depth = 1
    @has_printed_version = false
  end

  def handle_paper anElement
    @figureReader = FigureReader.new anElement
    @is_draft = ('dev' == anElement["status"])
    print_front_matter
    apply anElement
    render_revision_history
  end

  def title_bar_text
    return @root.at_xpath('/paper/title').text
  end

  def print_front_matter
    tr = "short" == @root['style'] ? 
      ShortFrontMatterTransformer : FrontMatterTransformer
    tr.new(@html, @root, @maker).handle(@root)
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
    @is_draft
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
    @html.hr('topSection') if @section_depth == 2
    apply anElement
    @section_depth -= 1
  end
  def handle_H anElement
    attrs = {:id => anchor_for(anElement.parent)}
    @html.h(@section_depth, attrs) {apply anElement}
  end
  alias :handle_h :handle_H
  def handle_topBox anElement;  end


  def handle_body anElement
    attrs = {'class' => 'bodySep'}
    @html.div('paperBody') do
      apply anElement
      @html.element('hr', attrs){}
      render_similar_articles
    end
  end
  def handle_appendix anElement
    @html.div('appendix') {apply anElement}
  end
  def render_similar_articles
    return if @maker.tags.empty?
    @html.div('similar-articles') do
      @html.h(2) {@html.text "For articles on similar topics…"}
      if  @maker.tags.size > 1
        @html.p {@html.text  "…take a look at the following tags:"}
        @html.p('tags') do
          @html << @maker.tags.collect{|t| t.link}.join(" ")
        end
      else
        @html.p do
          @html.text  "…take a look at the tag: "
          @html.span('tags') {@html << @maker.tags[0].link}
        end
      end
    end
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
  def anchor_for aSectionElement
    return aSectionElement['ID'] || 
      section_title(aSectionElement).to_anchor
  end
  def handle_cite anElement   
    bibref = @maker.bib_server[anElement['name']]
    bibref.link_around(@html, anElement)
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
  def handle_blikiRef anElement
    name = anElement['name']
    href = "http://martinfowler.com/bliki/#{name}.html"
    text = name.gsub(/[A-Z]/, ' \&')
    text += 's' if 'plural' == anElement['mode'] 
    @html.a_ref(href){@html.text text}
  end
  def handle_sidebar anElement
    @html.div('sidebar') {apply anElement}
  end
  def handle_soundbite anElement
    @html.div('soundbyte') do
      @html.p {apply anElement}
    end
  end
  def handle_figure anElement
    @html.div('figure') do
      if anElement['align']
        puts "can't handle alignment attribute in figure yet"
      end
      src = anElement['src']
      fig_num = @figureReader.number(src)
      @html.p('figureImage')do
        @html.element('a', 'name' => a_name(src)) {}
        img_attrs = copy_some_attributes(anElement, :width => :width, :src => :src)
        img_attrs['alt'] = "Figure #{fig_num}"
        # img_attrs['align'] = 'top'
        @html.element('img', img_attrs) {}
      end
      @html.p('figureCaption') do 
        @html.text "Figure #{fig_num}: "
        apply anElement
      end
    end
  end
  def a_name aString
    return aString.gsub("/", "_")
  end
  def handle_book anElement
   @html.amazon(anElement['isbn']){apply anElement}
  end
  def handle_tbd anElement
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
    @html.span('tbd') do
      @html.text "[TBD: #{anElement.text}]"
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
    @html.element('pre') {apply anElement}
  end

  def handle_insertCode anElement
    @maker.code_server.render_insertCode anElement, @html
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
    @html.element('blockquote', attrs) do
      apply anElement
      @html.p('quote-attribution') do
        text = lambda {@html.text "-- " + anElement['credit']}
        case
        when anElement['href'] then 
          @html.a_ref(anElement['href'], &text)
        when anElement.has_attribute?('isbn') then
          @html.amazon(anElement['isbn'], &text)
        else render_cite anElement
        end
      end
    end
  end
  def render_cite anElement
    ref = anElement['ref']
    bibref = @maker.bib_server[ref] if ref
    credit = anElement['credit'] || anElement['source']
    # HACKTAG use of source attr comes from bliki
    uri = anElement['url'] || (bibref && bibref.url)
    return unless ref || credit
    @html.text "-- "
    cite_text = credit || bibref.cite
    if uri
      @html.a_ref(uri){@html.text cite_text}
    else
      @html.text cite_text
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
  
end

#==== Full Author Transformer ================================


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
