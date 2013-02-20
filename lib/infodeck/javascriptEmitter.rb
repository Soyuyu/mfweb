class JavascriptEmitter
  def initialize
    @out = StringIO.new
  end
  def << arg
    @out << arg
  end
  def to_js
    @out.string
  end
end
