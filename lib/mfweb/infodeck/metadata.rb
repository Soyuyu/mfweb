module Mfweb::Infodeck
  class Metadata
    include Mfweb::Core
    def initialize maker, xml
      @maker = maker
      @xml = xml
    end
    def title
      @maker.title
    end
    def url
      Site.url_path @maker.uri + "/"
    end
    def description
      element = @xml.at_css('meta-description')
      return element ? element.text : fallback_description 
    end
    def fallback_description
      %[An infodeck entitled: "#{title}"]
    end
    def image
      img = @xml.at_css('meta-image')
      return nil unless img
      Site.url_path @maker.uri, img['src']
    end
    def publication_time
      elem = @xml.at_css('pub-date')
      return elem ? elem.text : nil
    end
    def authors
      #TODO replace tile class = "author' with author tag
      handles = @xml.css('author-twitter')
      return handles.map {|h| OpenStruct.new(twitter_handle: h.text)}
    end
  end
end
