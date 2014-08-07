module Mfweb::InfoDeck

  class SvgManipulator
    def initialize anSvgElement
      @doc = anSvgElement
    end

    def style anElement
      raise MissingStyleError.new(anElement) unless anElement['style']
      result = {}
      statements = anElement['style'].split(';')
      statements.each do |s|
        k,v = s.split ":"
        result[k.strip] = v.strip
      end
      return result
    end

    def replace_style anElement, styleHash
      value = styleHash.reject{|k,v| nil == v}.map{|k,v| "%s:%s;" %[k,v]}.join("")
      anElement['style'] = value
    end
    
    class MissingStyleError < StandardError 
      def initialize anElement
        @element = anElement
      end
      def message
        "missing style for text containing '#{@element.text}'"
      end     
    end
  end
end
