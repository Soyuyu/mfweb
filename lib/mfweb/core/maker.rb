module Mfweb::Core

  class Maker
    include FileUtils
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
      mkdir_p output_dir, verbose: false
      @skeleton.emit(@html, @transformer.title_bar_text, 
        meta_emitter: metadata_emitter) do |html|
        render_body
      end
    ensure
      @html.close     
    end

    def load
      @root = MfXml.root(File.new(@in_file))
      mkdir_p(output_dir)
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
    
    def img_out_dir path
      # how to modify the src attr of an img when emitting html
      # default is not to change it
      path
    end
    
    def resolve_includes aRoot
      aRoot.css('include').each do |elem|
        inclusion = Nokogiri::XML(File.read(input_dir(elem['src']))).root
        resolve_includes inclusion
        elem.replace inclusion.children
      end
    end

    def img_file_exts
      %w[png jpg svg]
    end

    def img_srcs
      img_file_exts.flat_map {|ext| Dir[input_dir('img/*.' + ext)] }
    end

  end
end
