BUILD_DIR = 'sample/build/'
MFWEB_DIR = './'

require 'rake/clean'
CLOBBER.include BUILD_DIR


require 'mfweb/infodeck/infodeck.rake'

namespace :infodeck do
  task :jasmine => ["^test", :js] do
    log "building test deck for jasmine tests"
    src = 'test/infodeck/jasmine/'
    target = BUILD_DIR + 'jasmine/'
    mkdir_p target, QUIET
    FileList['vendor/jasmine-1.3.1/*', 'vendor/jasmine-jquery*'].each {|f| install f, target, QUIET}
    maker = Mfweb::InfoDeck::DeckMaker.new(src+'deck.xml', target)
    maker.lede_font_file = 'sample/decks/IndieFlower.svg'
    maker.asset_server = Mfweb::InfoDeck::AssetServer.new("lib/mfweb/infodeck")
    maker.mfweb_dir = './'
    maker.google_analytics_file = nil
    sh "coffee  -j #{target}/infodeck-tester.js -c #{src}*.coffee", QUIET
    maker.run
    create_jasmine_file src, target
    log "use `rake server` to launch webserver to run tests at "
    log "http://localhost:2929/jasmine/test.html"
  end


  def create_jasmine_file src, target
    jasmine_target = target + "test.html"
    skeleton = create_jasmine_skeleton src
    js_files = Dir[File.join(src, 'js/*.js')]
    skeleton.js_files = js_files.map{|f| f.pathmap("%f")}
    Mfweb::Core::HtmlEmitter.open(jasmine_target) do |html|
      skeleton.emit(html, "jasmine infodeck")
    end
  end

  def create_jasmine_skeleton src
    result = JasmineSkeleton.new
    result.src = src
    return result
  end

  class JasmineSkeleton < Mfweb::InfoDeck::DeckSkeleton
    include Mfweb::InfoDeck
    attr_accessor :src
    def emit_header title
      #weird jasmine styling due to infodeck.css present
      super
      @html.css 'jasmine.css'
      @html.js 'jasmine.js'
      @html.js 'jasmine-html.js'
      @html.js 'jasmine-jquery-1.3.1.js'
      emit_js_in_header
    end

    def emit_jasmine_js
      @html.js 'infodeck-tester.js'
      @html.element('script', :type => 'text/javascript') do 
        @html << File.read(@src + 'jasmine-runner.js')
      end
    end
    def emit_js_in_header
      #from superclass (can't use super)
      emit_infodeck_js_files 
      @js_files.each {|f| @html.js f}
      
      @html.element('style') do
        @html << "#deck-container, .banner {display:none} body {text-align: left}"
      end
      emit_jasmine_js
    end
    def emit_js_in_body; end
    def emit_help_panel; end
  end


end
