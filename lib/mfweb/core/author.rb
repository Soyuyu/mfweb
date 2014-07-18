module Mfweb::Core
  class Author
    def initialize anElement
      raise "argument must be a nokogiri element" unless 
        anElement.kind_of? Nokogiri::XML::Element
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
      !! @data.at_css('author-photo')
    end
    def key
      @data['key']
    end
    def xml
      @data
    end
  end
end
