
task :ftest => ["^test", :js] do
  log "building test deck for jasmine tests"
  src = 'lib/test/infodeck/jasmine/'
  target = 'test/build/ftest/'
  mkdir_p target
  FileList['vendor/jasmine-1.3.1/*', 'vendor/jasmine-jquery*'].each {|f| install f, target}
  maker = InfoDeck::DeckMaker.new(src+'deck.xml', target)
  maker.lede_font_file = 'decks/Marydale.svg'
  sh "coffee  -j #{target}/infodeck-tester.js -c #{src}*.coffee"
  maker.run
  create_jasmine_file src, target
end





desc "run webrick server on build directory"
task :server do
  require 'webrick'
  include WEBrick

  port = 2929

  puts "URL: http://#{Socket.gethostname}:#{port}"
  mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
  mime_types.store 'js', 'application/javascript'
  mime_types.store 'svg', 'image/svg+xml'

  s = HTTPServer.new(:Port            => port,
                     :MimeTypes => mime_types,
                     :DocumentRoot    => 'lib/test/build')

  trap("INT"){ s.shutdown }
  s.start
end

