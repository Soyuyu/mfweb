require 'mfweb/infodeck'
task :decks => 'infodeck:decks'

namespace :infodeck do

  task :all

  # TODO refactor to new style with mention of file
  def infodeck_task input_dir, output_dir_name, files = nil, title = nil, maker_class = nil
    output_dir = BUILD_DIR + 'articles/' + output_dir_name
    input_file = File.join input_dir, 'deck.xml'
    maker_class ||= InfoDeck::DeckMaker
    maker = maker_class.new(input_file,output_dir)
    maker.lede_font_file = 'decks/Marydale.svg'
    slide_libs = FileList['lib/infodeck/*']
    deps = ['*', 'img/*', 'js/*'].map{|p| Dir[input_dir + p]}.flatten
    deps << BUILD_DIR + 'js/infodeck.js'
    file maker.output_file => deps + slide_libs do
      mkdir_p output_dir
      puts "building deck " + output_dir_name
      maker.run
    end
    task :all => maker.output_file
  end


  task :js => BUILD_DIR + 'js/infodeck.js'
  infodeck_coffee_srcs =  "#{MFWEB_DIR}lib/mfweb/infodeck/*.coffee" 
  file BUILD_DIR + 'js/infodeck.js' => FileList[infodeck_coffee_srcs] do |t|
    staging = 'gen/js/infodeck'
    mkdir_p staging, QUIET
    mkdir_p t.name.pathmap('%d'), QUIET
    sh "coffee -o #{staging} -c #{infodeck_coffee_srcs}", QUIET
    sh "cat #{staging}/*.js > #{t.name}", QUIET
    %w[jquery-1.7.2.min.js spin.js].each do |f|
      src = MFWEB_DIR + 'vendor/' + f
      install src, t.name.pathmap('%d'), QUIET
    end
  end
end

