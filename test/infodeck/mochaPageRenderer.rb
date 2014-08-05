  class MochaPageRenderer
    include Mfweb::InfoDeck
    def initialize src_dir, maker
      super()
      @src = src_dir
      @maker = maker
    end
    attr_reader :src
    attr_accessor :js_files
    def emit_header title
      @html.title "Mocha Tests"
      @html.element('meta', {:charset => "UTF-8"})
      @html.css 'mocha.css'
      @html.js 'mocha.js'
      @html.js 'chai.js'
      @html.js 'q.js'
      emit_js_in_header
      @html.js 'chai-jquery.js' # needs jquery to be loaded first 
    end

    def emit_body
     @html.body do
        @html.element('div', :id => 'deck-container') 
        @html.element('div', :id => "mocha") 
      end
    end

    def emit aStream, title, &block
      @html = Mfweb::Core::HtmlEmitter.new(aStream)
      @html.html do
        @html.head {emit_header title}
        emit_body &block
      end
    end


    def emit_mocha_js
      @html.element('script', :type => 'text/javascript') do 
        @html << File.read(@src + 'mocha-runner.js')
      end
      @html.js 'infodeck-mocha-tests.js'
    end
    def emit_js_in_header
      emit_js_components
     # emit_infodeck_js_files 
      @js_files.each {|f| @html.js f}
      
      @html.element('style') do
        @html << "#deck-container, .banner {display:none} body {text-align: left}"
      end
      emit_mocha_js
    end
    def title
      "Mocha Tests"
    end

    def emit_js_components
      @maker.js_for_html.each {|p| @html.js '../js/' + p}
    end

    def self.js_dependencies
      %w[jquery-1.7.2.min.js spin.js/spin.js]
    end
    def emit_infodeck_js_files
      deps = [] # self.class.js_dependencies.map{|p| File.basename(p)}
      (deps + %w[infodeck.js]).each do |f|
        @html.js "/js/" + f
      end
    end

  end
