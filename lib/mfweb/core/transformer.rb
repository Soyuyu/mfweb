module Mfweb::Core
# This does a recursive walk down the tree of the document calling
# #handle on each node. This superclass provides basic behavior for 
# each kind of node. 
# To render a particular kind of xml file create a subclass of this class. 
# To provide special behavior for an element called 'example' provide a method
# called 'handle_example anElement'. Such methods are found by 
# reflection and called when the tree walk finds the element. 
# If the element name contains dashes '-' you must replace them with 
# underscores. Eg handle_file_list will handle the file-list element.
#
# To continue processing on sub-elements use 'apply anElement'
#
# If you just want to copy an element to the output directly, just add
# it to #@copy_set

class Transformer
  include Mfweb::Core::HtmlUtils

  def initialize output, root
    @html = output  #an instance of HtmlEmitter
    @root = root  #root of this document
    @copy_set = [] #these elements will just be copied to the output
    @apply_set = [] #these elements will get the recursive apply
    @ignore_set = []
    @p_set = {}
    @span_set = {}
  end

  def render
    handle @root
  end

  def self.to_html anElement
    result = HtmlEmitter.new
    self.new(result, anElement).render
    return result.out
  end


  def handle aNode
    if nil == aNode
      handle_nil
    elsif aNode.cdata?
      handleCdataNode(aNode)
    elsif aNode.text?
      handleTextNode(aNode)
    elsif aNode.element?
      handle_element aNode
    elsif aNode.entity_ref?
      handleEntityRef(aNode)
    elsif aNode.kind_of? Nokogiri::XML::Document
      handle aNode.root
    else
      return #ignore comments and processing instructions
    end
  end
  def handle_element anElement
    handler_method = "handle_" + anElement.name.tr("-","_")
    if self.respond_to? handler_method
      self.send(handler_method, anElement)
    elsif  @apply_set.include?(anElement.name)
      apply anElement
    elsif @copy_set.include?(anElement.name)
      copy anElement
    elsif @p_set.keys.include?(anElement.name)
      @html.element(@p_set[anElement.name]) {apply anElement}
    elsif @span_set.keys.include?(anElement.name)
      @html.element_span(@span_set[anElement.name]) {apply anElement}
    elsif @ignore_set.include?(anElement.name)
      # shrug
    else
       default_handler anElement
    end
  end

  def default_handler anElement
    apply anElement
  end

  def copy anElement
    attr = attribute_hash(anElement)
    @html.element(anElement.name, attr) {apply anElement}
  end

  def attribute_hash anElement
    result = {}
    anElement.keys.each {|k| result[k] = anElement[k]}
    return result
  end

  def copy_some_attributes anElement, mappingHash
    result = {}
    mappingHash.each do |k,v|
      result[v] = anElement[k] if anElement.key?(k.to_s)
    end
    return result
  end

  def apply anElement
    # Handles all children. Equivalent to xslt apply-templates
    anElement.children.each {|e| handle(e)} if anElement
  end
  def handleTextNode aNode
    #HACKTAG this is an ugly hack to replace &apos; with ' since
    #IE cannot handle &apos. I haven't yet looked for a clean
    #way to do this nicely
    if aNode.to_s =~ /\S/
      output = ""
      output = aNode.to_s
      output.gsub!("&apos;", "'")
      @html << output
    end
  end
  def handleCdataNode aNode 
    output = aNode.content
    @html.cdata(output)
  end

  def handle_nil
    # shrug
  end

  def handleEntityRef aNode
    @html << aNode.to_s
  end

  def emit_amazon anElement, asin
    deprecated "use HtmlEmitter.amazon"
    @html.amazon(asin) {apply anElement}
  end

  def first_in_run? anElement
    not (anElement.previous_element && anElement.previous_element.name == anElement.name)
  end

  def collect_run e
    return (e.next_element && e.next_element.name == e.name) ? 
    [e] + collect_run(e.next_element) : [e]
  end

  def add_to_style attrHash, values
    return unless values
    attrHash[:style] ||= ""
    keys = values.reject{|k,v| nil == v}.keys
    attrHash[:style] += keys.sort.inject("") do |res, k| 
      res += "%s: %s;" % [k, values[k]] 
    end
    attrHash.delete(:style) if attrHash[:style].empty?
    return attrHash
  end

end

#==== Transformer Page Renderer ================

#TODO replace with the default maker that's easier to use

class TransformerPageRenderer 
  def initialize infile, outfile, transformerClass, skeleton
    @in_file = infile
    @out_file = outfile
    @transformer_class = transformerClass
    @skeleton = skeleton
  end

  def run
    load
    @skeleton.emit(@html, @transformer.title_bar_text){|html| render_body}    
  end

  def load
    @root = MfXml.root(File.new(@in_file))
    @html = HtmlEmitter.new(File.new(@out_file, 'w'))
    @transformer = create_transformer
  end

  def render_body
    @transformer.render
  end 

  def create_transformer
    @transformer_class.new(@html, @root, self)
  end
end

end
