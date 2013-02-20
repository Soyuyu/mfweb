module Mfweb::InfoDeck

class SvgManipulator
    def initialize anSvgElement
      @doc = anSvgElement
    end

    def style anElement
      raise "missing style" unless anElement['style']
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
  
end
end
