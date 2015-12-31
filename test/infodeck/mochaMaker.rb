class MochaMaker

  def initialize src, target
    @input_dir = src
    @output_dir = target
    @maker = Mfweb::InfoDeck::DeckMaker.new(@input_dir+'deck.xml', @output_dir)
  end
  
  def run
    mkdir_p @output_dir, QUIET
    FileList['vendor/*']
      .reject{|p| File.directory? p}
      .each {|f| install f, @output_dir, QUIET}
    create_infodeck
    create_test_file
    log message
  end

  def create_infodeck
    @maker.asset_server = Mfweb::InfoDeck::AssetServer.new("lib/mfweb/infodeck")
    @maker.mfweb_dir = './'
    @maker.google_analytics_file = nil
    @maker.css_paths += %w[sample/css]
    sh "coffee  -j #{@output_dir}/infodeck-mocha-tests.js -c #{@input_dir}*mocha*.coffee", QUIET
    Mfweb::Core::Site.init(TestSite.new)
    @maker.run
  end

  def create_test_file 
    renderer = MochaPageRenderer.new(@input_dir, self)
    test_target = File.join(@output_dir, "test.html")
    js_files = %w[contents.js]
    renderer.js_files = js_files.map{|f| f.pathmap("%f")}
    Mfweb::Core::HtmlEmitter.open(test_target) do |html|
      renderer.emit(html, renderer.title)
    end
  end

  def js_for_html
    @maker.js_for_html
  end

  
  class TestSite < Mfweb::Core::Site
    def load_framing
      @framing = Mfweb::Core::Framing.new nil, nil, []
    end
  end

  def message 
    "use `rake infodeck:mocha_server` to launch webserver to run tests at 
      http://localhost:2929/mocha/test.html
      see test deck at http://localhost:2929/mocha"
  end


end


