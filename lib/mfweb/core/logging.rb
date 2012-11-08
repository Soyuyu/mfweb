require 'logger'
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
$logger.formatter = proc do |sev, time, progname, msg|
  ('INFO' == sev) ? 
    "#{msg}\n" : 
    "[#{sev}] #{msg}\n"
end

def log *args
  if args.empty?
    $logger
  else
    $logger.info args[0] % args[1..-1]
  end
end

def log_dot
  $stdout <<  '.' 
  $stdout.flush
end

def log_cr
  puts
end

def log_with_level(arg)
  old_level = $logger.level
  $logger.level = arg
  begin
    yield
  ensure
    $logger.level = old_level
  end
end
