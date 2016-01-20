# -*- coding: utf-8 -*-
require 'rake/ext/string'

module Mfweb::Article
class ArticleMaker < Mfweb::Core::Maker
  attr_accessor :pattern_server, :code_server, :bib_server, :framing,
  :footnote_server, :catalog, :author_server, :refactoring_server, :transformer_class
  def initialize infile, outfile, framing = nil, transformerClass = nil
    @author_server = Mfweb::Core::Site.author_server
    super(infile, outfile, transformerClass, framing)
    @pattern_server = PatternServer.new
    @code_server = Mfweb::Core::CodeServer.new
    @bib_server = Bibliography.new(@in_file)
    @footnote_server = FootnoteServer.new(infile)
    @refactoring_server = RefactoringServer.new
    @code_dir = './'
    @img_out_dir = nil
    @show_all_installments = false
  end


  def load
    super
    puts "article #{@in_file}"
    @catalog = Mfweb::Core::Site.catalog
    @is_draft = ('draft' == @root['status'])
    @pattern_server.load
    @refactoring_server.load
    @bib_server.load
    resolve_includes @root
    @framing ||= default_framing
    @framing = @framing.as_draft if draft?
  end

  def default_framing
    Mfweb::Core::Site.framing
      .with_css(css_output)
      .with_banner_for_tags(tags)
      .with_added_js(js_imports)
  end
  
  def css_output
    'article.css'
  end

  def js_imports
    []
  end

  def draft?
    @is_draft || @show_all_installments
  end

  def authors
    @root.css('author').map{|tag| Mfweb::Core::Author.new(tag)}
  end

  def xml
    @root
  end

  def render_body
    flatten_future_installments if @show_all_installments
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

  def img_out_dir= path
    @img_out_dir = path
  end

  def img_out_dir path = nil
    case
    when nil == path then @img_out_dir || "."
    when path.start_with?('/') then path
    when @img_out_dir then File.join(@img_out_dir, path)
    else path
    end
  end

  def input_deps
    Dir[input_dir('**/*')]
  end

  def lib_deps
    lib_root = 'mfweb/lib/mfweb/'
    return Dir[lib_root + 'core/**/*'] + Dir[lib_root + 'article/**/*']
  end

  def dependencies
    input_deps + lib_deps
  end

  def author key
    @author_server.get key
  end
  def url
    Mfweb::Core::Site.target_to_url(@out_file)
  end
  def local_url
     Mfweb::Core::Site.target_to_local_url(@out_file)
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


  def show_all_installments
    @show_all_installments = true
  end

  def flatten_future_installments
    @root.css('future-installment').each do |fi|
      fi.children
        .reject{|e| 'installment-description' == e.name}
        .each {|e| e.parent = fi.parent}
    end
  end
  
end


end
