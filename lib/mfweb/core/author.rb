module Mfweb::Core
  class Author
    def initialize anElement
      @data = anElement
    end
    def name
      @data.at_css('author-name').text
    end
    def url
      @data.at_css('author-url').text
    end
    def photo 
      @data.at_css('author-photo')['src']
    end
  end
end
