require 'fileutils'
require 'erb'
include FileUtils
target = ARGV[0]
if File.exists? target
  puts "target dir <#{target}> already exists... exiting"
  exit(1)
end
puts "creating sample directory at #{target}"
mfweb_dir = File.dirname(File.expand_path $0)
cp_r(File.join(mfweb_dir, 'sample/'), target)
rakefile_template = File.join(mfweb_dir, 'template-sample', 'rakefile.erb')
rake_renderer = ERB.new(File.read(rakefile_template))
File.open(File.join(target, 'rakefile'), 'w') {|out| out << rake_renderer.result(binding)}


