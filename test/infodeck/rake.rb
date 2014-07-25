BUILD_DIR = 'build/test/'
MFWEB_DIR = './'

require 'mfweb/infodeck/infodeck.rake'

class TestSite < Mfweb::Core::Site
  def load_skeleton
    @skeleton = Mfweb::Core::PageSkeleton.new nil, nil, []
  end
end


namespace :infodeck do
  desc "builds infodeck mocha test runner"
  task :mocha => ["^test", :js] do
    log "building test deck for javascript tests"
    src = 'test/infodeck/jasmine/'
    target = BUILD_DIR + 'jasmine/'
    mkdir_p target, QUIET
    FileList['vendor/*']
      .reject{|p| File.directory? p}
      .each {|f| install f, target, QUIET}
    maker = Mfweb::InfoDeck::DeckMaker.new(src+'deck.xml', target)
    maker.asset_server = Mfweb::InfoDeck::AssetServer.new("lib/mfweb/infodeck")
    maker.mfweb_dir = './'
    maker.google_analytics_file = nil
    maker.css_paths += %w[sample/css]
    sh "coffee  -j #{target}/infodeck-tester.js -c #{src}infodeck-tester.coffee", QUIET
    sh "coffee  -j #{target}/infodeck-mocha-tests.js -c #{src}*mocha*.coffee", QUIET
    Mfweb::Core::Site.init(TestSite.new)
    maker.run
    mocha_target = BUILD_DIR + 'mocha'
    sh "cp -r #{target}* #{mocha_target}"
    create_test_file src, target, JasmineSkeleton.new(src)
    create_test_file src, mocha_target, MochaSkeleton.new(src)
    log "use `rake infodeck:mocha_server` to launch webserver to run tests at "
    log "http://localhost:2929/mocha/test.html"
    log "and"
    log "http://localhost:2929/jasmine/test.html"
    log "see test deck at http://localhost:2929/jasmine"
  end

  desc "runs server for infodeck mocha page"
  task :mocha_server do
    puts "in #{Dir.pwd}"
    require 'webrick'
    include WEBrick

    port = 2929

    puts "URL: http://#{Socket.gethostname}:#{port}"
    mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
    mime_types.store 'js', 'application/javascript'
    mime_types.store 'svg', 'image/svg+xml'

    s = HTTPServer.new(:Port            => port,
                       :MimeTypes => mime_types,
                       :DocumentRoot    => 'build/test')

    trap("INT"){ s.shutdown }
    s.start   
  end


  def create_test_file src, target, skeleton
    test_target = File.join(target, "test.html")
    js_files = ['contents.js']
    skeleton.js_files = js_files.map{|f| f.pathmap("%f")}
    Mfweb::Core::HtmlEmitter.open(test_target) do |html|
      skeleton.emit(html, skeleton.title)
    end
  end

  def create_test_skeleton src
    MochaSkeleton.new(src)
  end

  class JasmineSkeleton < Mfweb::InfoDeck::DeckSkeleton
    include Mfweb::InfoDeck
    attr_accessor :src
    def initialize src_dir
      super()
      @src = src_dir
    end
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
    def emit_logo; end
    def title
      "Jasmine Tests"
    end

  end

  class MochaSkeleton < Mfweb::InfoDeck::DeckSkeleton
    include Mfweb::InfoDeck
    def initialize src_dir
      super()
      @src = src_dir
    end
    attr_reader :src
    def emit_header title
      super
      @html.css 'mocha.css'
      @html.js 'mocha.js'
      @html.js 'chai.js'
      @html.js 'q.js'
      emit_js_in_header
      @html.js 'chai-jquery.js' # needs jquery to be loaded first 
    end

    def emit_mocha_js
      @html.element('script', :type => 'text/javascript') do 
        @html << File.read(@src + 'mocha-runner.js')
      end
      @html.js 'infodeck-mocha-tests.js'
    end
    def emit_js_in_header
      #from superclass (can't use super)
      emit_infodeck_js_files 
      @js_files.each {|f| @html.js f}
      
      @html.element('style') do
        @html << "#deck-container, .banner {display:none} body {text-align: left}"
      end
      emit_mocha_js
    end
    def emit_js_in_body
      # mocha test runner looks for this to inject its UI into
      @html.element('div', :id => "mocha") 
    end
    def emit_help_panel; end
    def emit_logo; end
    def title
      "Mocha Tests"
    end
  end


end
