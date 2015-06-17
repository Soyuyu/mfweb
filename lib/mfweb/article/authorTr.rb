module Mfweb::Article
  class FullAuthorTransformer < Mfweb::Core::Transformer
    include Mfweb::Core::XpathFunctions

    def initialize htmlRenderer, authorElement, maker = nil
      super htmlRenderer, authorElement, maker
      @apply_set = %w[author-bio]
      @copy_set = %w[p a i b]
    end
    def default_handler anElement
      $stderr.puts "Can't handle: #{anElement.name}"
    end

    def handle_author anElement
      @html.div('author') do 
        print_author_photo anElement if anElement.at_css('author-photo')
        print_name anElement
        apply anElement
      end
      @html.div('clear'){}
    end

    def print_author_photo authorElement = nil
      subject = authorElement || @root
      attrs = {}
      attrs['src'] = img_src(subject.at_css('author-photo'))
      name = xpath_only('author-name', subject).text
      attrs['alt'] = "Photo of #{name}"
      attrs[:width] = '80'
      @html.element('img', attrs) {}
    end

    def img_src photo
      case
      when @maker then @maker.img_out_dir photo['src']
      else photo['src']
      end
    end

    def  print_name authorElement = nil
      subject = authorElement || @root
      name = xpath_only('author-name', subject)
      url = xpath_only('author-url', subject)
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
    def handle_author_twitter anElement; end
  end
end
