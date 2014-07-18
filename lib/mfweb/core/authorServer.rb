module Mfweb::Core

  class AuthorServer
    def initialize glob
      @srcs = glob
      @authors = {}
    end
    def load
      Dir[@srcs].each do |f|
        xml = Nokogiri::XML(File.read(f))
        xml.css('author').each do |a|
          @authors[a['id']] = Author.new(a)
        end
      end
      self
    end
    def get key
      fail "No author with key <%s>" % key unless @authors.has_key? key
      @authors[key]
    end
  end

end
