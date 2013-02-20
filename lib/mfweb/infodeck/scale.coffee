window.rescaleViewport = ->
  # slide container width = 970, height = 640 (including banner and body margins)
  # aspect ratio = 1.52
  
  defaultContent = "minimum-scale = 1.0, initial-scale = 1.0"

  viewportTag = -> document.querySelector("meta[name=viewport]")

  # can't use jquery form below, as doesn't affect viewport
  #viewportTag = -> $("meta[name=viewport]")
  
  setViewport = (content) ->
    if viewportTag()?
      viewportTag().setAttribute('content', content)
    else
      meta = "<meta name = 'viewport' content = '#{content}'/>"
      $('head').append(meta)

  viewportContent = ->
    if viewportTag()? then viewportTag()['content'] else "no viewport tag"
      
  win = $(window)
  aspectRatio = win.width() / win.height()
  if 1.53 < aspectRatio # 1.53 ensures iPad never hits this leg
    scale = win.height() / 640
    scale = Math.floor(scale * 100) / 100
    content = "minimum-scale = #{scale}, initial-scale = #{scale}"
    setViewport(content)
  else
    #alert "starting else"
    viewportTag()?.remove()
    # another approach which I didn't like so much
    #viewport().setAttribute('content', defaultContent)

  #alert "viewport #{viewportContent()}"
  #
  # commented out alerts handy for debugging