module Mfweb::InfoDeck
  class BuildCollector
    def initialize
      @builds = []
    end
    def << arg
      @builds << arg
    end
    def emit_js out
      @builds.each{|b| b.emit_js(out)}
    end
  end

  class SlideBuildSet
    def initialize slide_id
      @builds = []
      @slide_id = slide_id
    end
    def << arg
      @builds << arg
      arg.slide_id = @slide_id
    end
    def immediate= aBuild
      @immediate = aBuild
      @immediate.slide_id = @slide_id
    end
    def emit_js out
      return if empty?
      out << "\n// for slide #{@slide_id}\n"
      @builds.each{|b| b.emit_js(out)}
      emit_immediate_build out
      emit_setup_build out
      out << "\n"
    end
    def emit_setup_build out
      out << "window.deck.addSetupBuild('#{@slide_id}', " 
      out << "\n  {"
      out << "\n    forwards: function () {"  
      out << setup_list.reverse.map(&:setup_forwards_code).join 
      out << "\n    },"
      out << "\n    backwards: function () {" 
      out << setup_list.map(&:setup_backwards_code).join 
      out << "\n    }"
      out << "\n  }"
      out << "\n);\n"
    end
    def emit_immediate_build out
      return unless @immediate
      out << "window.deck.addImmediateBuild('#{@slide_id}', "
      @immediate.emit_js_body out
      out << "\n);\n"
    end 
    def setup_list
      ([@immediate] + @builds).reject{|b| nil == b}
    end
    def empty?
      return (nil ==  @immediate) && @builds.empty?
    end
    def last
      @builds.last
    end
    def assert_ok
      @builds.each{|b| b.assert_ok}
    end
  end

  class Build
    attr_reader :elements
    attr_accessor :slide_id
    def initialize
      @elements = []
    end
    def emit_js out
      out << "window.deck.addBuild('#{slide_id}', "
      emit_js_body out
      out << "\n);\n"
    end
    def emit_js_body out
      out << "\n  {"
      out << "\n    forwards: "  << forwards_function << ",\n"
      out << "\n    backwards: " << backwards_function << "\n  }"
    end
    def hide selector
      if svg_element? selector
        @elements << ChangeClassElement.add(self, selector, 'hidden')
      else
        @elements << JQueryMethod.new(self, selector, "fadeOut()", "fadeIn()")
      end
    end
    def show selector
      if svg_element? selector
        @elements << ChangeClassElement.remove(self, selector, 'hidden')
      else
        @elements << JQueryMethod.new(self, selector, "fadeIn()", "fadeOut()")
      end
    end
    def svg_element? selector
      svg_elements = ['g', 'path', 'svg']
      element_names = selector.split.map{|a| a.split(".").first}.reject{|a| a.empty?}
      return element_names.any? {|e| svg_elements.include? e}
      # see svg-note below for why this is needed
    end
    
    def char selector
      @elements << ChangeClassElement.add(self, selector, 'charred')
    end
    def add_class selector, css_class
      @elements << ChangeClassElement.add(self, selector, css_class)
    end
    def remove_class selector, css_class
      @elements << ChangeClassElement.remove(self, selector, css_class)
    end
    def js_builder target
      @elements << JsBuilderElement.new(target)
    end
    def forwards_function
      "function () {" + forwards_code + "\n    }"
    end
    def forwards_code
      @elements.inject("") do |acc, e|
        acc << element_prefix << e.forwards_js
      end
    end
    def setup_forwards_code
      @elements.inject("") do |acc, e|
        acc << element_prefix << e.setup_forwards_js
      end
    end
    def element_prefix
      "\n" + " " * 6
    end
    def backwards_function
      "function () {" + backwards_code + "\n    }"
    end
    def backwards_code
      @elements.inject("") do |acc, e|
        acc << element_prefix << e.backwards_js
      end
    end
    def setup_backwards_code
      @elements.inject("") do |acc, e|
        acc << element_prefix << e.setup_backwards_js
      end
    end
    def merge! other
      @elements += other.elements.map{|e| e.with_build(self)}
    end
    def assert_ok
      bad_elements = @elements.select do |e| 
        ChangeClassElement == e.class && self != e.build
      end
      raise "bi-directional link mismatch" unless bad_elements.empty?
    end
  end

  class ChangeClassElement
    attr_reader :build
    def self.add aBuild, selector, cssClass
      self.new aBuild, selector, cssClass, "addClass", "removeClass"
    end
    def self.remove aBuild, selector, cssClass
      self.new aBuild, selector, cssClass, "removeClass", "addClass"
    end
    def initialize build, selector, cssClass, forwards_function, backwards_function
      @build = build
      @selector = selector
      @cssClass = cssClass
      @forwards_function = forwards_function
      @backwards_function = backwards_function
    end
    def full_selector
      "#%s %s" % [@build.slide_id, @selector]
    end
    def forwards_js
      "$('%s').%s('%s');" % [full_selector, @forwards_function, @cssClass]
    end
    def backwards_js
      "$('%s').%s('%s');" % [full_selector, @backwards_function, @cssClass]
    end
    def setup_forwards_js
      set_transition_timing + "\n" + backwards_js
    end
    def setup_backwards_js
      set_transition_timing + "\n" + forwards_js
    end
    def set_transition_timing
      s = full_selector
      "$('#{s}, #{s} p, #{s} ul, #{s} pre').addClass('fadeable');"
    end
    def with_build aBuild
      self.class.new(aBuild, @selector, @cssClass, @forwards_function, @backwards_function)
    end
  end

  class JsBuilderElement

    def initialize target
      @target = "window." + target
    end
    
    def forwards_js
      @target + ".forwards();"
    end
    def backwards_js
      @target + ".backwards();"
    end
    def setup_forwards_js
      @target + ".setup_forwards();"
    end
    def setup_backwards_js
      @target + ".setup_backwards();"
    end
    def with_build aBuild
      self
    end
  end

  class JQueryMethod
    def initialize build, selector, forwards_function, backwards_function
      @build = build
      @selector = selector
      @forwards_function = forwards_function
      @backwards_function = backwards_function
    end
    def forwards_js
      "#{jqe}.%s;" % @forwards_function
    end
    def backwards_js
      "#{jqe}.%s;" % @backwards_function
    end
    def jqe
      "$('%s')" % full_selector
    end
    def with_build aBuild
      self.class.new(aBuild, @selector, @forwards_function, @backwards_function)
    end
    def full_selector
      "#%s %s" % [@build.slide_id, @selector]
    end
    def setup_forwards_js
      backwards_js
    end
    def setup_backwards_js
      forwards_js
    end
  end
     
end


################  svg-note ################
#
# the awkward switching based on a guess on whether we are talking to
# an svg element is due to jquery not working on svg elements and the
# need to hide an element that's faded out.
# 
# I need to hide any faded out element in case it covers a visible
# element and prevents clicking on a link. To do this with nice fading
# is tricky timing with css class changes - jquery doesn't do css
# class changes within its animation queue. But jquery solves this
# problem by supplying fadeIn and fadeOut methods, which do the fade
# and set display to none. This is just what I need for html elements
# but doesn't work for svg elements, hence use of a class change, and
# the awkward guessing method
