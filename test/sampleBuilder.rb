task :sample => [ :test, 'build/index.html']

file 'build/index.html' do
  puts "building sample site"
  rm_r 'build' if File.exists? 'build'
  sh 'ruby make-sample.rb build'
  cd 'build' do
    sh 'rake'
  end
end


task :server => 'build/index.html' do
  cd 'build' do
    sh 'rake server'
  end
end
  
