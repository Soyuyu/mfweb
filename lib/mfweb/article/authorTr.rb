module Mfweb::Article
  class FullAuthorTransformer < Mfweb::Core::Transformer
    include Mfweb::Core::XpathFunctions

    def initialize htmlRenderer, rootElement
      super htmlRenderer, rootElement
      @apply_set = %w[author-bio]
      @copy_set = %w[p a i b]
    end
    def default_handler anElement
      $stderr.puts "Can't handle: #{anElement.name}"
    end

    def handle_author anElement
      @html.div('author') do 
        photo = xpath_only('author-photo', anElement)
        if photo
          attrs = {}
          attrs['src'] = photo['src']
          name = xpath_only('author-name', anElement).text
          attrs['alt'] = "Photo of #{name}"
          attrs[:width] = '80'
          @html.element('img', attrs) {}
        end
        print_name anElement
        apply anElement
      end
      @html.div('clear'){}
    end

    def  print_name authorElement
      name = xpath_only('author-name', authorElement)
      url = xpath_only('author-url', authorElement)
      @html.p('name') do
        if url
          @html.element('a', href: url.text, rel: 'author') {@html.text name.text }
        else
          @html.text name.text
        end
      end
    end

    def handle_author_name anElement ; end
    def handle_author_url anElement; end
    def handle_author_photo anElement; end
  end
end
