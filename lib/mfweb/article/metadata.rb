module Mfweb::Article
  class Metadata
    def initialize maker
      @maker = maker
    end
    def title
      @maker.title
    end
    def url
      @maker.url
    end
    def description
      result = @maker.xml.at_css('meta-description')
      return result ? result.text : fallback_description
    end
    def fallback_description
      %[A long-form article entitled: "#{title}"]
    end
    def image
      nil
    end
    def publication_time
      @maker.xml.at_css('version')['date']
    end
    def authors
      @maker.authors
    end
  end
end
