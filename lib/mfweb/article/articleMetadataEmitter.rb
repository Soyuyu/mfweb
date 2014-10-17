module Mfweb::Article
  class ArticleMetadataEmitter
    def initialize output, root
      @html = output
      @root = root
      @errors = []
    end
    def emit
      check_validity

      card_val = image ? 'summary_large_image' : 'summary'
      @html.meta 'twitter:card', card_val
      @html.meta 'twitter:site:id', '16665197'
      @html.meta 'og:title', title
      @html.meta 'og:url', url
      @html.meta 'og:description', description
      image_val = image ? image : fallback_image
      @html.meta 'og:image', image_val
      @html.meta 'og:site_name', 'martinfowler.com'
      @html.meta 'og:type', 'article'
      @html.meta 'og:article:modified_time', publication_time
      authors.each{|a| emit_author a}
    end
    def title
      raise 'subclass responsibility'
    end
    def url
      raise 'subclass responsibility'
    end
    def description
      raise 'subclass responsibility'
    end
    def image
      raise 'subclass responsibility'
    end
    def check_validity
      check("title <#{title}> is more than 70 chars") {title.length <= 70}
      check("description for  <#{title}> is more than 200 chars"){description.length < 200}
      raise "meta data errors: \n%s" % @errors.join("\n") unless @errors.empty?
    end
    def check message
      @errors << message unless yield
    end
    def emit_author anAuthor
      @html.meta 'twitter:creator', anAuthor.twitter_handle if anAuthor.twitter_handle
    end
    def authors
      @root.css('author').map{|tag| Mfweb::Core::Author.new(tag)}
    end
    def fallback_image
      "http://martinfowler.com/mf.jpg"
    end
    def publication_time
      raise 'subclass responsibility'
    end
      
  end
end
