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
    def twitter_handle
      e = @data.at_css('author-twitter')
      case
      when e.nil? then nil
      when e['handle'] then e['handle']
      when e.text then fail "twitter handle inside text" #TODO remove
      else nil
      end
    end
    def twitter_id
      e = @data.at_css('author-twitter')
      return e ? e['id'] : nil
    end
    def has_twitter?
      @data.at_css('author-twitter')
    end
  end
end
