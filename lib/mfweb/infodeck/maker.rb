
module Mfweb::InfoDeck

  class DeckMaker
    include Mfweb::Core
    include FileUtils
    attr_reader :output_dir, :js
    attr_accessor :code_server, 
       :asset_server, :google_analytics_file, :css_paths, :mfweb_dir
    def initialize input_file, output_dir
      @input_file = input_file
      @output_dir = output_dir
      @partials = {}
      @asset_server = AssetServer.new('.')
      @css_paths = %w[lib/mfweb/infodeck css]
      @google_analytics_file = 'partials/footer/google-analytics.html'
      @mfweb_dir = "mfweb/"
      @css_out = StringIO.new
    end

    
    

    def run
      begin
        mkdir_p @output_dir, :verbose => false
        unless File.exists? @mfweb_dir + 'lib/mfweb/infodeck.rb'
          raise "unable to find mfweb library at <#{@mfweb_dir}>" 
        end
        @code_server = Mfweb::Article::CodeServer.new(input_dir + 'code/')
        @gen_dir = File.join('gen', input_dir)
        @js = JavascriptEmitter.new
        @build_collector = BuildCollector.new
        @root = Nokogiri::XML(File.read(@input_file)).root
        load_included_decks(@root)
        mkdir_p @gen_dir, :verbose => false
        import_local_ruby
        install_svg
        install @mfweb_dir + 'lib/mfweb/infodeck/public/*'
        install @mfweb_dir + 'lib/mfweb/infodeck/modernizr.custom.js'
        install_graphics
        install_jquery_svg
        js_files = Dir[File.join(input_dir, 'js/*.js')]
        js_files.each {|f| install f}
        skeleton = DeckSkeleton.new
        skeleton.js_files = js_files.map{|f| f.pathmap("%f")}
        skeleton.maker = self
        skeleton.table_of_contents = table_of_contents
        coffee_glob = File.join(input_dir, 'js/*.coffee')
        unless Dir[coffee_glob].empty?
          sh "coffee -o #{@output_dir} -c #{coffee_glob}"
          skeleton.js_files += Dir[coffee_glob].map{|f| f.pathmap("%n.js")}
        end
        skeleton.js_files << 'contents.js'
        coffee_src = File.join(input_dir, 'deck.coffee') 
        if File.exist?(coffee_src)
          coffee_target = File.join(@output_dir, 'deck.js')
          sh "coffee -j #{coffee_target} -c #{coffee_src}"
          skeleton.js_files << coffee_target.pathmap('%f')
        end
        @root.css('partial').each {|e| add_partial e['id'], e}
        transform_slides
        build_css
        build_index_page skeleton
        generate_contents
        File.open(File.join(@output_dir, 'contents.js'), 'w') {|f| f << @js.to_js}
        generate_fallback
      rescue
        rm_r @output_dir
        raise $!
      end
    end 

    def table_of_contents
      titles = @root.css('slide[title]')
      return nil if titles.empty?
      return titles.
        map{|e| "<p><a href='#%s'>%s</a></p>" % [e['id'], e['title']]}.
        join("\n")
    end

    def asset name
      @asset_server[name]
    end

    def build_index_page skeleton
      title = @root['title'] || "Untitled Infodeck"
      HtmlEmitter.open(output_file) do |html|
        skeleton.emit(html, title) do |html|
          html.div('init') do
            IndexTransformer.new(html, @root, self).render
          end
        end
      end
    end

    def input_dir
      @input_file.pathmap("%d/")
    end
    
    def load_included_decks aDeckRoot
      aDeckRoot.css('deck[src]').each do |d|
        inclusion = Nokogiri::XML(File.read(File.join(input_dir, d['src']))).root
        load_included_decks inclusion
        d.replace(inclusion)
      end
    end

    def install_svg
      Dir[File.join(input_dir, 'img/*.svg')].each do |f| 
         install_svg_file f
      end
      install File.join(@gen_dir, '*.svg')
    end
    
    def install_svg_file file_name
      SvgInstaller.new(file_name, @output_dir).run
    end

    def output_file
      File.join @output_dir, 'index.html'
    end

    def uri
      @output_dir.pathmap "%{build,}p"
    end

    def import_local_ruby
      ruby_files = Dir[input_dir + '/*.rb'] - [input_dir + '/rake.rb']
      ruby_files.each {|f| require f}
    end

    def install glob
      files = Dir[glob]
      files.each do |f|
        log.warn "missing file to install %s", f unless File.exist? f
        cp f, @output_dir, :verbose => false
      end
    end
    
    def install_graphics
      %w[png jpg].each {|ext| install(File.join(input_dir, 'img', '*.' + ext))}
    end

    def base_scss
        local_scss = File.join input_dir, 'deck.scss'
        return File.exist?(local_scss) ? local_scss : asset('infodeck.scss')
    end

    def build_css
      sass = Sass::Engine.new(File.read(base_scss), 
                              :syntax => :scss, :load_paths => @css_paths)
      File.open("#{@output_dir}/infodeck.css", 'w') do |out| 
        out << sass.render
        return if @css_out.string.empty?
        out << "\n\n/*" + '-' * 50 + "*/\n\n"
        out << @css_out.string
      end
    end


    JQUERY_SVG_FILES = %w[jquery.svg.min.js jquery.svgdom.min.js jquery.svganim.min.js]
    JQUERY_CSS_FILES = %w[jquery.svg.css]

    def install_jquery_svg
      (JQUERY_CSS_FILES + JQUERY_SVG_FILES).each do |f|
        install @mfweb_dir + 'vendor/jquerysvg/' + f
      end
    end     

    

    def img_file file_name
      first = input_dir + '/img/' + file_name
      return first if File.exists? first
      second = @gen_dir + file_name
      return second if File.exists? second
      raise "unable to fine image file for " + file_name
    end
    def add_partial key, anElement
      raise "duplicate partial definition for " + key if @partials.has_key? key
      @partials[key] = anElement
    end

    def partial key
      raise "missing partial " + key unless @partials.has_key? key
      @partials[key]
    end

    def task_dependencies
      rakefile = File.join input_dir, 'rake.rb'
      slide_files + [base_scss, rakefile]
    end
    def draft?
      'draft' == @root['status']
    end
    def allowed_fonts
      #should try to coordinate changes here with skeleton
      ['Inconsolata', 'Open Sans']
    end

    def transform_slides
      @root.css('slide').each do |anElement|
        output_file = "%s/%s.html" % [@output_dir, anElement['id']]
        HtmlEmitter.open(output_file) do |html|
          tr = transformer_class.new(html, anElement, self)
          tr.render
          @build_collector << tr.builds
        end
      end
    end

    def transformer_class
      DeckTransformer
    end

    def generate_contents
      contents = @root.css('slide').map{|e| e['id']}.
        map{|id| {'uri' => id + '.html'}}
      data = {'contents' => contents}
      @js << "function initialize_deck() {\n" 
      @js << "deck = new Infodeck(" << 
        data.to_json << 
        ");"
      @build_collector.emit_js(@js)
      @js << "};" << "\n"
      @js << "initialize_deck();" << "\n"
      @js << "window.deck.load();" 
    end

    def generate_fallback
      return unless fallback_skeleton
      HtmlEmitter.open(output_dir + '/fallback.html') do |html|
        transformer = FallbackTransformer.new(html, @root, self)
        title = "fallback for " + @root['title']
        fallback_skeleton.emit(html, title) {transformer.render}
      end
    end
    def fallback_skeleton; nil; end # hook method
    def put_css aString
      @css_out << aString
    end
    def catalog
      Site.catalog
    end
    def catalog_key
      return File.basename(@output_dir)
    end
    def tags 
      if catalog && catalog[catalog_key]
        return catalog[catalog_key].tags
      else
        return []
      end
    end
  end
end

