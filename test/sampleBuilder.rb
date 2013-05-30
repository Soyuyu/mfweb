SAMPLE_TARGET = 'build/sample/'
SAMPLE_TOUCHFILE = SAMPLE_TARGET + 'build/index.html'

desc "builds sample srcs for tests"
task :sample => [ :test, :clobber, SAMPLE_TOUCHFILE]

file SAMPLE_TOUCHFILE do
  puts "\n\nbuilding sample site in #{SAMPLE_TARGET}"
  puts "use this only for testing changes for mfweb scripts"
  puts "use `rake server` to serve these pages"
  puts ; puts
  mkdir_p 'build'
  sh "ruby make-sample.rb #{SAMPLE_TARGET}"
  cd SAMPLE_TARGET do
    sh 'rake'
  end
end

desc "run server for sample directory"
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
                     :DocumentRoot    => SAMPLE_TARGET + 'build')

  trap("INT"){ s.shutdown }
  s.start
end
