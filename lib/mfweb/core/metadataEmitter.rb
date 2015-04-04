module Mfweb::Core
  class MetadataEmitter
    def initialize output, aMetadataWrapper
      @html = output
      @src = aMetadataWrapper
      @errors = []
    end
    def emit
      check_validity

      @html.meta 'twitter:card', twitter_card
      @html.meta 'twitter:site:id', Site.twitter_site_id if Site.twitter_site_id
      @html.meta 'og:title', title
      @html.meta 'og:url', @src.url
      @html.meta 'og:description', @src.description
      image_val = @src.image ? @src.image : fallback_image
      @html.meta 'og:image', image_val
      @html.meta 'og:site_name', 'martinfowler.com'
      @html.meta 'og:type', 'article'
      @html.meta 'og:article:modified_time', @src.publication_time
      emit_author 
    end
    def title
      @src.title
    end
    def check_validity
      check("title <#{title}> is more than 70 chars") {title.length <= 70}
      check(
        "description for <%s> is %d cars (limit is 200)" %
        [title, @src.description.length]) do
          @src.description.length < 200
      end

      if  ! (@src.description.length < 200)
        puts "<\n#{@src.description}\n"
      end

      raise "meta data errors: \n%s" % @errors.join("\n") unless
      @errors.empty?
    end
    def check message
      @errors << message unless yield
    end
    def emit_author
      a = @src.authors.find{|i| i.has_twitter?}
      if a
        @html.meta 'twitter:creator:id', a.twitter_id if a.twitter_id
        handle = a.twitter_handle
        if handle
          @html.meta 'twitter:creator', a.twitter_handle
          fail "bad twitter handle #{handle}" unless "@" == handle[0]
        end
      end
    end
    def first_twitter_handle
      @src.authors
        .map{|a| a.twitter_handle}
        .compact
        .first
    end
    def first_twitter_id
      @src.authors
        .map{|a| a.twitter_id}
        .compact
        .first
    end
    def fallback_image
      "http://martinfowler.com/logo-sq.png"
    end
    def twitter_card
      return case
             when @src.respond_to?(:twitter_card) && @src.twitter_card 
               @src.twitter_card
             when @src.image then 'summary_large_image'
             else 'summary'
             end
    end
    
  end
end
