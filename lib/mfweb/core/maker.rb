module Mfweb::Core

  class Maker
    attr_accessor :transformer_class, :transformer
    def initialize infile, outfile, transformerClass, skeleton
      @in_file = infile
      @out_file = outfile
      @transformer_class = transformerClass
      @skeleton = skeleton
    end

    def run
      load
      render
    end

    def render
      @skeleton.emit(@html, @transformer.title_bar_text, 
        meta_emitter: metadata_emitter) do |html|
        render_body
      end
    ensure
      @html.close     
    end

    def load
      @root = MfXml.root(File.new(@in_file))
      @html = HtmlEmitter.new(File.new(@out_file, 'w'))
      @transformer = create_transformer
    end

    def render_body
      @transformer.render
    end 

    def create_transformer
      transformer_class.new(@html, @root, self)
    end

    def input_dir *path
      dir = @in_file.pathmap("%d/")
      File.join dir, *path
    end

    def output_dir *path
      dir = @out_file.pathmap("%d/")
      File.join dir, *path
    end

    def metadata_emitter 
      nil
    end

  end
end
