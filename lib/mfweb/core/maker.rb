#TODO check to see if this class is ever used. ArticleMaker subclasses off TransformerPageRenderer that's defined in transformer.rb. Should unify to only one maker class


module Mfweb::Core

class Maker
 attr_accessor :skeleton, :transformer
  def initialize out_file, in_file, transformer_class, 
    skeleton, title_bar_text = nil

    @out_file = out_file
    @in_file = in_file
    @transformer_class = transformer_class
    @skeleton = skeleton
    @title_bar_text =  title_bar_text
  end
  def run
    load
    render
  end
  def render
    @skeleton.emit(@html, title_bar_text){@transformer.render}
  end
  def load
    @root = MfXml.root(File.new(@in_file))
    @html = HtmlEmitter.new(File.new(@out_file, 'w'))
    @transformer = create_transformer
  end
  def create_transformer
    @transformer_class.new(@html, @root)
  end
  def title_bar_text
    @title_bar_text || transformer.title_bar_text
  end
end

end
