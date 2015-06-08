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
      result = @maker.xml.at_css('meta-description') ||
        (@maker.xml.at_css('intent') if 'pattern' == @maker.xml.name)
      return result ? result.text.squish : fallback_description
    end
    def fallback_description
      %[A long-form article entitled: "#{title}"]
    end
    def image
      img = @maker.xml.at_css('meta-image')
      return nil unless img
      return Mfweb::Core::Site.url_path('articles', @maker.img_out_dir(img['src']))
    end
    def publication_time
      @maker.xml.at_css('version')['date']
    end
    def authors
      @maker.authors
    end
  end
end
