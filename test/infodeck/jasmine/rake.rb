class JasmineSkeleton < Mfweb::InfoDeck::DeckSkeleton
  include InfoDeck
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

def create_jasmine_skeleton src
  result = JasmineSkeleton.new
  result.src = src
  return result
end

def create_jasmine_file src, target
  target_dir = target.pathmap "%d"
  skeleton = create_jasmine_skeleton src
  js_files = Dir[File.join(src, 'js/*.js')]
  skeleton.js_files = js_files.map{|f| f.pathmap("%f")}
  Mfweb::Core::HtmlEmitter.open(target) do |html|
    skeleton.emit(html, "jasmine infodeck")
  end
end

namespace :infodeck do

  desc "build web page for jasmine tests"
  task :jasmine => [:js] do
    target = BUILD_DIR + "test.html"
    puts "building jasmine test file at " + target
    create_jasmine_file 'decks/jasmine/', target
  end

end
