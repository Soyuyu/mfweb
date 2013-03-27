module Mfweb::InfoDeck
  class DeckSkeleton
    include Mfweb::Core::HtmlUtils
    attr_accessor :js_files, :maker
    def initialize 
      @css = []
    end
    def emit aStream, title, &block
      @html = aStream.kind_of?(Mfweb::Core::HtmlEmitter) ? aStream : 
        Mfweb::Core::HtmlEmitter.new(aStream)
      emit_doctype
      @html.html do
        @html.head {emit_header title}
        emit_body &block
      end
    end
    def emit_doctype
      @html << '<!DOCTYPE html>' << "\n"
    end
    def emit_header title
      @html.title title
      #TODO replace this css call with @import in scss
      @html.css 'http://fonts.googleapis.com/css?family=Inconsolata'
      @html.element('meta', {:charset => "UTF-8"})
      @html.css "infodeck.css"
      DeckMaker::JQUERY_CSS_FILES.each {|f| @html.css f}
      @css.each{|uri| @html.css uri}
      @html.js 'modernizr.custom.js'
      @html.js 'svg_redirect.js'
    end
     
    def emit_body
      @html.body do
        @html.div('banner') do
          emit_logo
          emit_navigator
          emit_help_button
          emit_deck_status
        end
        emit_help_panel
        @html.element('div', :id => 'deck-container') do
          emit_loading_slide
          yield @html if block_given?
          emit_goto_panel
        end
        emit_touch_panel
        emit_js_in_body
      end
    end
    def emit_js_in_body
      emit_js_files
      emit_google_analytics
    end
    def emit_js_files
      emit_infodeck_js_files
      @js_files.each {|f| @html.js f}
    end
    def emit_logo
      @html.a_ref("http://martinfowler.com") do
        @html.element_span 'img', {:src => 'mf-name-white.png', 
          :class => "logo"}
      end
    end
    def emit_navigator
      @html.element_span 'img', {:src => 'left-arrow.svg',
        :class => "deck-prev-link", :title => "previous slide"}
      @html.element_span 'img', {:src => 'right-arrow.svg',
        :class => "deck-next-link", :title => "next slide"}
    end
    def emit_deck_status
      @html.element('span', :class => 'deck-status', :title => "go to slide") do
        @html.span('deck-status-current')
        @html << "/"
        @html.span('deck-status-total')
      end
      @html.element('span', :class => 'deck-permalink', :title => 'permalink') {@html.text '#'}
    end
    def emit_help_button
      @html.element_span 'img', {:src => 'help-button.svg',
        :class => "deck-help", :title => "show help"}
    end
    def emit_help_panel
      @html.div('deck-help-panel') do
        helpfile = @maker.asset 'help.markdown'
        @html << Kramdown::Document.new(File.read(helpfile)).to_html
      end
    end
    def emit_goto_panel
      # @html << File.read('vendor/deck.js/extensions/goto/deck.goto.html')
      @html.element('form', :action => '.', 
                    :method => 'get', :class => 'deck-goto-panel') do
        @html.element('label', :for => 'deck-goto-input') {@html.text "Go to slide:"}
        @html.element('input', :class => 'deck-goto-input', :type => 'text')
        @html.element('input', :type => 'submit', :value => "Go")
      end 
    end
    def emit_touch_panel
      @html.div('deck-touch-panel') do
        @html.p('button previous') do
          @html.text "Previous"
          @html.span('extra') {@html.text "<br/>(always active)"}
        end
        @html.p('button next') do
          @html.text "Next"
          @html.span('extra') {@html.text "<br/>(always active)"}
        end
        @html.p('button first') {@html.text "First"}
        @html.p('button last') {@html.text "Last"}
        @html.p('button goto') {@html.text "Go to<br/>slide #"}
      end
    end
    def emit_infodeck_js_files
      %w[jquery-1.7.2.min.js spin.js infodeck.js].each do |f|
        @html.js "/js/" + f
      end
      DeckMaker::JQUERY_SVG_FILES.each do |f|
        @html.js f
      end
    end
    def emit_google_analytics
      if @maker.google_analytics_file
        @html << File.read(@maker.google_analytics_file)
      end
    end
    def emit_loading_slide
      @html.div("deck-loading-message") do
        @html.p {@html << "Loading... please wait"}
      end
    end
  end
end
