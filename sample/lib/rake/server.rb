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
                     :DocumentRoot    => BUILD_DIR)

  trap("INT"){ s.shutdown }
  s.start
end
