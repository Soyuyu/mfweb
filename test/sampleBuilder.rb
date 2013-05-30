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


task :server => SAMPLE_TOUCHFILE do
  cd SAMPLE_TARGET + 'build' do
    puts "=" * 40, "in #{Dir.pwd}"
    sh "rake server"
  end
end
  
