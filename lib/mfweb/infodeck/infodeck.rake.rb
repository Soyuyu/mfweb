require 'mfweb/infodeck'
task :decks => 'infodeck:all'

namespace :infodeck do

  task :all

  def infodeck_task maker
    slide_libs = FileList['lib/infodeck/*', "#{MFWEB_DIR}lib/mfweb/infodeck/**/*"]
    deps = ['*', 'img/*', 'js/*'].map{|p| Dir[maker.input_dir + p]}.flatten
    deps << BUILD_DIR + 'js/infodeck.js'
    file maker.output_file => deps + slide_libs do
      puts "building deck " + maker.output_file.pathmap('%d')
      maker.js_dir = BUILD_DIR + 'js'
      maker.run
    end
    task 'infodeck:all' => maker.output_file
  end


  task :js => BUILD_DIR + 'js/infodeck.js'
  infodeck_coffee_srcs =  Mfweb::InfoDeck::JsCompiler.srcs(MFWEB_DIR)
  file BUILD_DIR + 'js/infodeck.js' => FileList[infodeck_coffee_srcs] do |t|
    jc = Mfweb::InfoDeck::JsCompiler.new(t.name, 'gen/js/infodeck')
    jc.mfweb_dir = MFWEB_DIR
    jc.run
  end
  
end


