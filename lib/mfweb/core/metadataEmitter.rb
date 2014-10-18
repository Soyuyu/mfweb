module Mfweb::Core
  class MetadataEmitter
    def initialize output, aMetadataWrapper
      @html = output
      @src = aMetadataWrapper
      @errors = []
    end
    def emit
      check_validity

      card_val = @src.image ? 'summary_large_image' : 'summary'
      @html.meta 'twitter:card', card_val
      @html.meta 'twitter:site:id', Site.twitter_site_id
      @html.meta 'og:title', title
      @html.meta 'og:url', @src.url
      @html.meta 'og:description', @src.description
      image_val = @src.image ? @src.image : fallback_image
      @html.meta 'og:image', image_val
      @html.meta 'og:site_name', 'martinfowler.com'
      @html.meta 'og:type', 'article'
      @html.meta 'og:article:modified_time', @src.publication_time
      @src.authors.each{|a| emit_author a}
    end
    def title
      @src.title
    end
    def check_validity
      check("title <#{title}> is more than 70 chars") {title.length <= 70}
      check("description for  <#{title}> is more than 200 chars") {
        @src.description.length < 200}
      raise "meta data errors: \n%s" % @errors.join("\n") unless @errors.empty?
    end
    def check message
      @errors << message unless yield
    end
    def emit_author anAuthor
      @html.meta 'twitter:creator', anAuthor.twitter_handle if anAuthor.twitter_handle
    end
    def fallback_image
      "http://martinfowler.com/logo-sq.png"
    end
  end
end
