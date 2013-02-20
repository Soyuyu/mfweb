class TouchParser

  constructor: ->
    @clear()

  
  touchstart: (event) ->
    return unless @shouldAccept(event)
    @lastTouchEvent = event
    if event.originalEvent.touches.length == 1      
      @startPoint = event.originalEvent.touches[0]
    else
      @multiTouch = true
      
  touchend: (event) ->
    end = event.originalEvent.changedTouches[0]
    if @considerGesture(event)
      result = @determineGesture(@startPoint, end)
      $(end.target).trigger(result)
    @clear()


  clear: ->
    @multiTouch = false
    @startPoint = undefined


  considerGesture: (event) ->
    return @startPoint? and not @multiTouch

  shouldAccept: (event) ->
    return false if event.originalEvent.target.localName == "a"
    return true

  determineGesture: (start, end) ->
    tapTolerance = 10
    if Math.abs(end.pageX - start.pageX) < tapTolerance &&
      Math.abs(end.pageY - start.pageY) < tapTolerance
        tapEvent = $.Event "touchTap", {
          pageX: end.pageX
          pageY: end.pageY
          }
        return tapEvent
       
      

window.touchParser =  new TouchParser