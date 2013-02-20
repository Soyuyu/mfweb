module InfoDeck
  class SvgInstaller
    def initialize input_file, output_dir
      @input_file = input_file
      @output_dir = output_dir
    end
    def run
      parse_file
      add_viewbox @svg_doc.root
      svg_out = @input_file.pathmap("#{@output_dir}/%f")
      File.open(svg_out,'w') {|out| out << @svg_doc.to_xml}
    end
    def add_viewbox root
      unless root.key? 'viewBox' 
        root['viewBox'] = "0 0 %s %s" % [root['width'], root['height']]
        root['preserveAspectRatio'] ="xMinYMin meet"
      end     
    end
    def parse_file
      @svg_doc = Nokogiri::XML(File.read(@input_file))
    end
  end
  class SvgLayerSplittingInstaller < SvgInstaller
    def run
      parse_file
      add_viewbox @svg_doc.root
      layers_of(@svg_doc).each {|layer| install_layer_only layer}
      svg_out = @input_file.pathmap("#{@output_dir}/%f")
      File.open(svg_out,'w') {|out| out << @svg_doc.to_xml}
     end
    def install_layer_only layer
      inkscape_ns = @svg_doc.namespaces['xmlns:inkscape']
      this_label = layer.attribute_with_ns('label', inkscape_ns)
      copy = @svg_doc.dup
      layers_of(copy).
        select {|e| e.attribute_with_ns('label', inkscape_ns).value != this_label.value}.
        each{|e| e.remove}
      svg_out =  @input_file.pathmap("#{@output_dir}/%n-") + this_label.value + '.svg'
      File.open(svg_out,'w') {|out| out << copy.to_xml}
    end
    def layers_of aDocument
      aDocument.root.xpath("svg:g[@inkscape:groupmode = 'layer']")
    end
  end
end
