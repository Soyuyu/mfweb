module Mfweb::Article

class ArticleMaker < Mfweb::Core::TransformerPageRenderer
  attr_accessor :pattern_server, 
    :code_server, :bib_server, :footnote_server, :catalog
  def initialize infile, outfile, skeleton = nil, transformerClass = nil
    @catalog = Mfweb::Core::Site.catalog
    super(infile, outfile, transformerClass, skeleton)
    @skeleton ||=  Mfweb::Core::Site.
      skeleton.with_css('article.css').
      with_banner_for_tags(tags)
    puts "#{@in_file} -> #{@out_file}" #TODO move to rake task
    @pattern_server = PatternServer.new
    @code_server = CodeServer.new
    @bib_server = Bibliography.new
    @footnote_server = FootnoteServer.new(infile)
    @code_dir = './'
  end

  def load
    super
    resolve_includes @root
    @skeleton = @skeleton.as_draft if 'draft' == @root['status']
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


  def key
    return File.basename(@out_file, '.html')
  end

  def tags
    # some old papers are not registered in catalog
    if @catalog && @catalog[key]
      return @catalog[key].tags
    else
      return []
    end
  end
  def resolve_includes aRoot
    aRoot.css('include').each do |elem|
      inclusion = Nokogiri::XML(File.read(input_dir(elem['src']))).root
      resolve_includes inclusion
      elem.replace inclusion.children
    end
  end
end


end
