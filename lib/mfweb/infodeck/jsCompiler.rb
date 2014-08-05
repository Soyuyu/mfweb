module Mfweb::InfoDeck

  class JsCompiler
    attr_accessor :mfweb_dir
    def initialize output, staging_dir
      @output = output
      @staging_dir = staging_dir
      @mfweb_dir = "mfweb/"
    end
    
    def run
      mkdir_p @staging_dir, QUIET
      mkdir_p @output.pathmap('%d'), QUIET
      sh "coffee -o #{@staging_dir} -c #{srcs}", QUIET
      sh "cat #{@staging_dir}/*.js > #{@output}", QUIET
    end  

    def srcs
      self.class.srcs(@mfweb_dir)
    end

    def self.srcs mfweb_root
      File.join(mfweb_root, "lib/mfweb/infodeck/*.coffee")
    end


  end
end

# not sure was worth building this class out from the original simpler
# rake code. Leaving it in for the moment while I think about it
