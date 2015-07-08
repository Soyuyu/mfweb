module Mfweb::Article
  class RichMaker < ArticleMaker
    # This is a new generation of maker, designed to be responsible
    # for all that's needed to make an article, including file copies
    # and css generation (that is traditionally handled by separate
    # rake tasks


    def initialize infile, outfile = nil
      out = outfile || default_outfile(infile)
      super infile, out
      @img_out_dir = basename
      @code_server = Mfweb::Core::CodeServer.new(input_dir('code'))
    end

    def render
      super
      render_css
      build_img
    end
    
    def base_scss
      input_dir('style.scss')
    end

    def custom_css?
      File.exist? base_scss
    end

    def default_outfile infile
      Site.build_path('articles', infile.pathmap("%n.html"))
    end

    def basename
      File.basename(@out_file.pathmap("%n"))
    end

    def css_output
      custom_css? ? basename + ".css" : super
    end

    def scss_paths
      %w[css mfweb/css] + [input_dir]
    end

    def render_css
      return unless custom_css?
      sass = Sass::Engine.new(File.read(base_scss), 
        :syntax => :scss, :load_paths => scss_paths)
      File.open(output_dir(css_output), 'w') do |out| 
        out << sass.render
      end
    end

    def default_bibliography
      Bibliography.new(@in_file, 'biblio.xml')
    end

    def build_img
      target =  output_dir(@img_out_dir)
      mkdir_p target
      img_srcs.each {|f| install f, target}
    end
      
  end
end
