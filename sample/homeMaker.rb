class HomeMaker
  def initialize target
    @target = target
  end
  def run
    output = Nokogiri::HTML::Builder.new do |html|
      html.html do
        html.h1 "A crude home page"
        html.ul do
          html.li do
            html.a "Simple", :href => 'articles/simpleArticle.html'
          end
          html.li do
            html.a "Flexible", :href => 'articles/flexible.html'
          end
        end
     end
    end
    File.open(@target, 'w') {|f| f << output.to_html}
  end
end
