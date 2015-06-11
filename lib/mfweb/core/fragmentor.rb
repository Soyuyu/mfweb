module Mfweb::Core
  class Fragmentor
    # Pulls source code fragments out of source files. Any text file
    # can be chopped. Surround between <codeFragment name = 'THE_NAME'>
    # and </codeFragment

    attr_reader :class, :frags
    def initialize file
      @file = file
      @class = nil
      @frags = {}
    end

    def run
      raise MissingFragmentFile, @file unless FileTest.exists? @file
      begin
        extract_fragments
      rescue
        raise FragmentorError.new(@file, $!)
      end
    end

    def extract_fragments
      fragsByName = Hash.new
      fragNames = []
      File.new(@file).each_line do |line|
        match_class_name line
        if line =~ %r{</codeFragment>}
          @frags[fragNames.last] = CodeFragment.new(fragsByName[fragNames.last], @class)
          fragNames.pop
        end

        fragNames.each do |name|
          fragsByName[name] << line if line !~/<\/{0,1}codeFragment.*>/
        end

        if line =~ /<codeFragment/
          line =~ /name\s*=\s*"(\S*)"/
          fragNames << $1
          fragsByName[$1] = ""
        end
      end
    end

    def [] frag
      if @frags[frag]     
        return @frags[frag]
      else
        raise(MissingFragment, frag)
      end
    end
    
    def match_class_name line
      return if @class #only want the first match
      line =~ /(class\s+(\w*))/
      @class = $~[1] if $~
    end

  end

  class FragmentorError < StandardError
    def initialize file, base
      @file = file
      @base = base
    end
    def message
      "Error fragmenting %s: %s" % [@file, @base]
    end
  end

  class CodeFragment
    attr_reader :result, :class
    def initialize code, klass = ""
      @result, @class = code, klass
    end
  end


  class FragmentError < StandardError
  end
  class MissingFragmentFile < FragmentError 
  end
  class MissingFragment < FragmentError
  end
end
