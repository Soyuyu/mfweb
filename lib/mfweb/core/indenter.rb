module Mfweb::Core
  class Indenter
    def initialize aString
      @src = aString
    end
    def leading arg
      offset = arg - first_line_amount
      return case 
             when 0 == offset then @src
             when offset > 0 then add_indent(offset)
             when offset < 0 then remove_indent(-offset)
             end             
    end
    def lines
      @src.split("\n")
    end
    def first_line_amount
      match = /\S+/.match(lines.first)
      return match ? match.begin(0) : 0
#      rescue
#      raise format "HECK\n%s\n%s", lines.first.class, '-' * 40
    end
    def add_indent arg
      lines.map {|line| " " * arg + line}.join("\n")
    end
    def remove_indent arg
      lines.each do |line|
        fail IndentationTruncationException.new(arg, line) unless 
          /^\s*$/ =~ line[0..arg - 1]
      end
      return lines.map{|line| line[arg..-1]}.join("\n")
    end
  end

  class IndentationTruncationException < Exception
    def initialize indentAmount, aString
      @indent_amount
      @src = aString
    end
    def to_s
      "Indentation Truncation (%d) on <%s>" % [@indent_amount, @src]
    end
  end
end
