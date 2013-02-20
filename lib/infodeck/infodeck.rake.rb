require 'mfweb/core'

#task :decks => ['infodeck:qtest', 'infodeck:decks']
task :decks => 'infodeck:decks'

namespace :infodeck do

require 'infodeck/maker'
verbose false

task :decks

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
  task :decks => maker.output_file
end

task :js => BUILD_DIR + 'js/infodeck.js'
file BUILD_DIR + 'js/infodeck.js' => FileList['lib/infodeck/*.coffee'] do |t|
  staging = 'gen/js/infodeck'
  mkdir_p staging
  mkdir_p t.name.pathmap('%d')
  sh "coffee -o #{staging} -c lib/infodeck/*.coffee"
  sh "cat #{staging}/*.js > #{t.name}"
  %w[vendor/jquery-1.7.2.min.js vendor/spin.js/spin.js].each do |f|
    install f, t.name.pathmap('%d')
  end
end


TEST_FILES = FileList['lib/test/*Tester.rb']

require 'test/infodeck/rake'

def quiet_task name
  cmd = "rake %s" % name
  output = `#{cmd}`
  if 0 == $?.exitstatus 
    puts "tests OK"
  else
    puts  output
    raise "tests FAILED"
  end  
end

task :qtest do
  quiet_task "infodeck:ftest"
end



require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "lib/test"
  t.test_files = TEST_FILES
  t.verbose = false 
  t.warning = true
end

task :val_deploy => :build do
  bads = Dir[BUILD_DIR + '**/*.svg'].reject{
    |f| Nokogiri::XML(File.read(f)).css('text').empty?}
  unless bads.empty?
    puts "---- svg with text " + "-" * 40
    bads.each {|f| puts "#{f} has text"}
    raise "there are svgs with text nodes " 
  end
end

def say *args
  if args.size > 1
    puts args[0] % args[1..-1]
  else
    puts args
  end
end


desc "one unit test"
task :one do
  require 'test/unit/testsuite'
  require 'test/unit/ui/console/testrunner'
  require 'test/fontpathTester.rb'
  require 'test/transformerTester.rb'

  suite = Test::Unit::TestSuite.new
  test = "test_long_line_wraps"
  #suite << FontPath::FontPathTester.new('test_long_line_wraps')
  suite << InfoDeck::DeckTransformerTester.new('test_postion_injects_left_if_no_left_or_right')
  #suite << InfoDeck::DeckTransformerTester.new('test_position_does_not_inject_default_left_if_right_present')

  Test::Unit::UI::Console::TestRunner.run(suite)
end
end

