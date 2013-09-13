module Mfweb::Core
  class Author
    def initialize anElement
      @data = anElement
    end
    def name
      @data.at_css('author-name').text
    end
    def url
      @data.at_css('author-url') ? @data.at_css('author-url').text : nil
    end
    def photo 
      @data.at_css('author-photo')['src'] if has_photo?
    end
    def has_photo?
      true == @data.at_css('author-photo')
    end
  end
end
