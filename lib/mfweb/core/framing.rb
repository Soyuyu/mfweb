module Mfweb::Core
  module MesherSource
    def body_start
      return self.with_output(HtmlEmitter.new).emit_pre_content.out
    end
    def body_end
      return self.with_output(HtmlEmitter.new).emit_post_content.out
    end
    def css_paths
     @css
    end
  end

class Framing
  include HtmlUtils
  include MesherSource
  attr_reader :meta_tags, :footer, :banner, :js
  def initialize header, footer, cssArray
    @header = header
    @footer = footer
    @css = Array cssArray
    @js = []
    @js_inline = []
    @banner_photo = nil
    @is_draft = false
    @navmenu = ""
    @use_viewport = false
  end
  def emit aStream, title, meta_emitter: nil
    @html = HtmlEmitter.on aStream
    emit_doctype
    @html.html do
      @html.head do
        @html.title title
        emit_viewport if @use_viewport
        emit_encoding
        meta_emitter.emit if meta_emitter
        @css.each{|uri| @html.css uri}
      end
      @html.body do
        emit_pre_content
        @html.element('div', :id => 'content') do
          emit_draft_notice if @is_draft
          yield @html
        end
        emit_post_content
      end
    end
  end
  def emit_pre_content
    @html << @header
    @html.div('div', id: 'top-navmenu') {@html << @navmenu} if @navmenu
    return @html
  end
  def emit_post_content
    @html.div('div', id: 'bottom-navmenu') {@html << @navmenu} if @navmenu
    @html << @footer
    @js.each {|url| @html.js url}
    @js_inline.each {|f| emit_inline_js f}
    return @html
  end
  def emit_file file_name, title, &block
    File.open(file_name, 'w') {|f| emit(f, title, &block)}
  end
  def emit_inline_js file_name
    @html.js_inline(File.read(file_name))
  end
  def emit_doctype
    @html << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' << "\n"
  end
  def emit_encoding
    @html << '<meta http-equiv="Content-type" content="text/html;charset=UTF-8" />'
  end
  def emit_viewport
    @html << '<meta name="viewport" content="width=device-width, initial-scale=1" />'
  end
  def with_output aStreamOrEmitter
    with_iv(:@html, HtmlEmitter.on(aStreamOrEmitter))
  end
  def with_css *arg
    with_iv :@css, arg.flatten
  end
  def with_added_css *arg
    with_css(@css + arg)
  end
  def with_banner_photo arg
    with_iv :@header, custom_banner(:photo_fn => arg)
  end
  def with_banner_for_tags arg
    return with_banner_photo(pick_photo(arg))
  end
  def to_s
    "Framing with css: %s" % @css
  end
  def with_js *arg
    with_iv :@js, arg.flatten
  end
  def with_added_js *arg
    with_js(@js + arg)
  end
  def with_inline_js *arg
    with_iv :@js_inline, arg.flatten
  end
  def as_draft
    with_iv :@is_draft, true
  end
  def emit_draft_notice
    @html.div("draft-notice") do
      @html.h(1) {@html.text "Draft"}
      @html.p {@html.text "This article is a draft.<br/>Please do not share or link to this URL until I remove this notice"}
    end
  end
  def with_banner htmlString
    with_iv :@header, htmlString
  end
  def with_footer htmlString
    with_iv :@footer, htmlString
  end
  def with_navmenu htmlString
    with_iv :@navmenu, htmlString
  end
  def without_viewport
    with_iv :@use_viewport, false
  end
  def with_viewport
    with_iv :@use_viewport, true
  end
  private
  def with_iv name, value
    result = self.dup
    result.instance_variable_set(name, value)
    return result    
  end
end

end
