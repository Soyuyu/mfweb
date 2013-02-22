require 'mfweb/infodeck'
task :decks => 'infodeck:all'

namespace :infodeck do

  task :all

  def infodeck_task maker
    slide_libs = FileList['lib/infodeck/*']
    deps = ['*', 'img/*', 'js/*'].map{|p| Dir[maker.input_dir + p]}.flatten
    deps << BUILD_DIR + 'js/infodeck.js'
    file maker.output_file => deps + slide_libs do
      puts "building deck " + maker.output_file.pathmap('%d')
      maker.run
    end
    task 'infodeck:all' => maker.output_file
  end


  task :js => BUILD_DIR + 'js/infodeck.js'
  infodeck_coffee_srcs =  "#{MFWEB_DIR}lib/mfweb/infodeck/*.coffee" 
  file BUILD_DIR + 'js/infodeck.js' => FileList[infodeck_coffee_srcs] do |t|
    staging = 'gen/js/infodeck'
    mkdir_p staging, QUIET
    mkdir_p t.name.pathmap('%d'), QUIET
    sh "coffee -o #{staging} -c #{infodeck_coffee_srcs}", QUIET
    sh "cat #{staging}/*.js > #{t.name}", QUIET
    %w[jquery-1.7.2.min.js spin.js/spin.js].each do |f|
      src = MFWEB_DIR + 'vendor/' + f
      install src, t.name.pathmap('%d'), QUIET
    end
  end
end

