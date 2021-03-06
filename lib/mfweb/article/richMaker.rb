module Mfweb::Article
  class RichMaker < ArticleMaker
    # This is a new generation of maker, designed to be responsible
    # for all that's needed to make an article, including file copies
    # and css generation (that is traditionally handled by separate
    # rake tasks

    attr_accessor :js_components

    def initialize infile, outfile = nil
      out = outfile || default_outfile(infile)
      super infile, out
      @img_out_dir = basename
      @js_out_dir = basename
      @code_server = Mfweb::Core::CodeServer.new(input_dir('code'))
      @js_components = []
    end

    def self.mf *args
      return self.new(*args).configure_mf
    end

    def render
      super
      render_css
      build_js
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

    def base_js
      input_dir('custom.js')
    end

    def custom_js?
      File.exist? base_js
    end

    def js_output
      basename + '.js'
    end

    def build_js
      return unless custom_js?
      install base_js, output_dir(js_output)
      js_target = output_dir(@js_out_dir)
      mkdir_p js_target
      Dir[input_dir('js/*')].each{|p| install p, js_target}      
    end

    def js_imports
      custom_js? ? js_components + [js_output] : []
    end
    
    def build_img
      target =  output_dir(@img_out_dir)
      mkdir_p target
      img_srcs.each {|f| install f, target}
    end

    def configure_mf
      @pattern_server = PatternServer.new('patternList.xml')
      @bib_server = Bibliography.new(@in_file, 'biblio.xml')
      @refactoring_server = RefactoringServer.new('refactoring/entries')
      return self
    end

    def full_copy_maker out_file
      result = self.dup
      result.out_file = out_file
      result.show_all_installments
      return result
    end
  end
end
