module SvgManipulators
  class Ft < SvgManipulator
    def run
      @doc.css('.comms').each{|e| e.remove_attribute('style')}
    end
  end
end
