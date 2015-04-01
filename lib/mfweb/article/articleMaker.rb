# -*- coding: utf-8 -*-
module Mfweb::Article

class ArticleMaker < Mfweb::Core::Maker
  attr_accessor :pattern_server, :code_server, :bib_server, 
  :footnote_server, :catalog, :author_server, :refactoring_server, :img_dir
  def initialize infile, outfile, skeleton = nil, transformerClass = nil
    @catalog = Mfweb::Core::Site.catalog
    @author_server = Mfweb::Core::Site.author_server
    super(infile, outfile, transformerClass, skeleton)
    @pattern_server = PatternServer.new
    @code_server = Mfweb::Core::CodeServer.new
    @bib_server = Bibliography.new(infile)
    @footnote_server = FootnoteServer.new(infile)
    @refactoring_server = RefactoringServer.new
    @code_dir = './'
    @img_dir = "./"
  end

  def load
    super
    puts "#{@in_file} -> #{@out_file}" #TODO move to rake task
    @is_draft = ('draft' == @root['status'])
    @pattern_server.load
    @refactoring_server.load
    resolve_includes @root
    @skeleton ||=  Mfweb::Core::Site.
      skeleton.with_css('article.css').
      with_banner_for_tags(tags)
    @skeleton = @skeleton.as_draft if draft?
  end

  def draft?
    @is_draft
  end

  def authors
    @root.css('author').map{|tag| Mfweb::Core::Author.new(tag)}
  end

  def xml
    @root
  end

  def render_body
    @transformer.render
  end

  def transformer_class
    return @transformer_class if @transformer_class
    return case @root.name
           when 'paper'   then PaperTransformer
           when 'pattern' then PatternHandler
           else fail "no transformer for #{@in_file}"
           end
    
  end


  def catalog_ref
    return @root['catalog-ref'] || File.basename(@out_file, '.html')
  end

  def tags
    # some old papers are not registered in catalog
    if @catalog && @catalog.src(@in_file)
      return @catalog.src(@in_file).tags
    else
      return []
    end
  end
  def author key
    @author_server.get key
  end
  def url
    Mfweb::Core::Site.target_to_url(@out_file)
  end
  def title
    case @root.name
      when 'paper' then @root.at_css('title').text
      else fail "unable to find title for #{@in_file}"
    end
  end
  def metadata_emitter
    Mfweb::Core::MetadataEmitter.new(@html, Metadata.new(self))
  end
  def render_end_box
    EndBoxRenderer.new(@html, self).run
  end

  class EndBoxRenderer
    include Mfweb::Core::HtmlUtils

    def initialize html, maker
      @maker = maker
      @html = html
    end
    def run
      @html.div('end-box') do
        emit_shares @maker.title, @maker.url
        render_similar_articles
      end
    end
    def render_similar_articles
      return if @maker.tags.empty?
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
end
end
