module Mfweb::Article

  class FrontMatterTransformer < PaperTransformer
    def initialize *args
      super(*args)
    end
    def handle_paper anElement
      assert_valid
      print_title
      print_topImage
      print_abstract
      @html.div('frontMatter') do
        @html.div('frontLeft') do
          print_version
          print_authors
          print_translations anElement
          print_tags
          print_topBox
        end
        @html.div('frontRight') do
          print_contents
        end
      end
    end

    def assert_valid
      credits = xpath("//credits")
      unless credits.empty?
        authors = xpath("//author")
        raise "credits but no authors" if authors.empty?
      end
    end

    def print_title
      handle(@root.at_css('title'))
      handle(@root.at_css('subtitle'))
    end
    def handle_title anElement
      @html.h(1) {apply anElement}
    end
    def handle_subtitle anElement
      @html.p("subtitle") {apply anElement}
    end
    
    def print_abstract
      handle(@root.at_css('abstract'))
    end

    def handle_abstract anElement
     @html.p('abstract'){@html.i{apply anElement}}
    end
   
  def print_topImage
    elem = xpath_only('//paper/topImage')
    return unless elem
    attrs = {}
    case elem['layout']
      when 'full' then attrs['class'] = 'fullPhoto'
      when nil then attrs['id'] = 'topImage'
    end
    width = elem['width']
    attrs['style'] = "width: #{width}px;" if width
    @html.element('div', attrs) do
      @html.element('img', {:src => elem['src']}){}
      render_photo_credit elem
      if elem.has_text?
        @html.p {apply elem}
      end
    end
  end

    def print_version 
      latest_version = xpath_first('version')
      date = latest_version['date']
      @html.p('date') {@html.text print_date(date)}
    end

    def print_authors 
      xpath('/*/author').each {|e| handle e}
    end

    def handle_author anElement
      FullAuthorTransformer.new(@html, resolve_author(anElement)).render
    end

    def resolve_author anElement
      anElement['key'] ? @maker.author(anElement['key']).xml : anElement
    end

    def print_translations anElement
      trans = xpath('//paper/translation')
      return if trans.empty?
      @html.div('translations') do
        @html.b {@html.text "Translations: "}
        trans.each do |t|
          @html.a_ref(t['url']) do
            @html.text t['language']
          end
          @html.text dot_sep
        end
      end
    end
    
    def print_tags
      return if @maker.tags.empty?
      message = @maker.tags.size > 1 ?
        "Find similar articles to this by looking at these tags: " :
        "Find similar articles at the tag: "
      @html.div('tags') do
        @html.b {@html << message  }
        @html << @maker.tags.collect{|t| t.link}.join(dot_sep)
      end
    end

    def print_topBox 
      topBox = xpath('//paper/topBox').first
      handle topBox if topBox
    end


    def handle_topBox anElement
      @html.div('topBox') do
        apply anElement
      end
    end


    def print_contents 
      @html.div('contents') do
        @html.h(2) {@html.text 'Contents'}
        @html.ul  do
          xpath('body/section').each {|s| print_contents_for s}
        end
        print_sidebars      
      end
    end

    def print_contents_for aSection
      @html.li do
        @html.a_ref("##{anchor_for(aSection)}") do
          @html.text(section_title(aSection))
        end
        unless contents_subsections(aSection).empty?
          @html.ul {contents_subsections(aSection).each {|s| print_contents_for s} }
        end
      end
    end

    def contents_subsections aSection
      xpath('section', aSection)
    end

    def print_sidebars
      sidebars = xpath('body//sidebar[h]')
      unless sidebars.empty?
        @html.h(3){@html.text 'Sidebars'}
        @html.ul  do
          sidebars.each {|s| print_contents_for s}
        end
      end         
    end

    def handle_body anElement;  end #skip
    def default_handler anElement; end
  end

  class ShortFrontMatterTransformer < FrontMatterTransformer
    def handle_paper anElement
      assert_valid
      print_title
      print_topImage
      print_abstract
      @html.div('short-front') do
        print_authors
        print_version
      end
      print_translations @root
    end
    def print_authors 
      elements = xpath('/*/author')
      raise "can't do multiple authors on short form" if elements.size > 1
      FullAuthorTransformer.new(@html, resolve_author(elements[0])).render
    end
  end

end
