module Mfweb::Article

#======== Bibliography ==========================
# Holds data to support generating a bibliography

# Reads data from the supplied bibliography file and
# puts in hyperlinks to books and urls in the bibliography.

class Bibliography
  def initialize *files
    @entries = {}
    @bib_files = files
  end
  def load
    @bib_files.each {|f| load_file f}
    return self
  end
  def load_file file
    if FileTest.exists? file
      load_stream(File.new(file).read)
    else
      puts $deferr, "Unable to find bibiography file: " + file
    end
  end
  def load_stream aStream
    root = Nokogiri::XML(aStream)
    refs = root.xpath('//bibliography/ref')
    refs.each {|e| load_bib_entry e}
    self
  end
  def load_bib_entry aRefElement
    ref = BibRef.new aRefElement
    @entries[ref.name] = ref 
  end
  def element_text anElement
    return anElement ? anElement.text : nil
  end
  def extractIsbn aRefElement
    book_elem = aRefElement.xpath('book').first
    if book_elem
      return book_elem.xpath('isbn').first.text
    else
      isbn_only = aRefElement.xpath('isbn').first
      return isbn_only ? isbn_only.text : nil
    end
  end
  def size
    @entries.size
  end
  def loaded?
    return ! @entries.empty?
  end
  def [] arg
    $stderr.puts "Bibilography not loaded" unless self.loaded?
fail unless self.loaded?
    result = @entries[arg]
    result ? result : NullBibRef.new(arg)
  end
  def to_s
    @entries.map{|e| e.to_s}.join("\n")
  end
end

class BibRef
  include  Mfweb::Core::HtmlUtils
  def initialize anElement
    raise 'heck' unless anElement
    @xml = anElement
  end
  def name
    @xml['name']
  end
  def url
    case 
    when @xml['url'] then @xml['url']
    when url_element then url_element.text
    when isbn then 'http://www.amazon.com/exec/obidos/ASIN/' + isbn
    else nil
    end
  end
  def url_element
    @xml.xpath('.//url').first
  end
  def text
    @xml['text']
  end
  def null?
    false
  end
  def cite
    return @xml.xpath('cite').first ? @xml.xpath('cite').first.text : "[#{name}]"
  end
  def link_around htmlEmitter, aCiteElement = nil, &block
    case 
    when block_given?
      link_around_block htmlEmitter, &block
    when aCiteElement && aCiteElement.text.empty?
      link_around_block(htmlEmitter){htmlEmitter.text cite}
    when aCiteElement
     link_around_block(htmlEmitter){htmlEmitter.text aCiteElement.text}
    else 
      throw "no cite element or block given"
    end
  end
  def link_around_block htmlEmitter, &block
    case
    when @xml['url']
      htmlEmitter.a_ref(@xml['url'], &block)
    when url_element
      htmlEmitter.a_ref(url, url_element.attributes, &block)
    when isbn
      htmlEmitter.amazon(isbn, &block)
    else
      block.call
    end
  end
  def isbn
    book_elem = @xml.at_css('book')
    case
    when @xml.has_attribute?('isbn')
      @xml['isbn']
    when book_elem
      book_elem.at_css('isbn').text
    when @xml.at_css('isbn')
      @xml.at_css('isbn').text
    else
      nil
    end
  end
end
class NullBibRef < BibRef
  def null?
    return true
  end
  def initialize arg
    raise "No name passed in call to Bib Server" unless arg
    @name = arg
  end
  def name
    puts 'missing bib reference for : ' + @name
    return '** missing ' + @name
  end
  def url
    nil
  end
  def link_around htmlEmitter, aCiteElement = nil
    puts 'missing bib reference for : ' + @name
    htmlEmitter.span('todo') {htmlEmitter << "[TODO Add Bib Reference for '%s']" % @name}
  end
end

end
