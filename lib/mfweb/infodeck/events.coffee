fixLocalLinks = (root, shouldPushLocation) ->
  $('a', root).click (ev) ->
    window.deck.pushSlideUrl() if shouldPushLocation
    if $(this).attr('href').match('^#')
      window.deck.goToHash($(this).attr('href'))
      ev.preventDefault()


$('#deck-container').on 'deck-becameCurrent', ->
  fixLocalLinks('#deck-container', true)      
  $('.deck-help').off()
  $('.deck-help').click -> $('.deck-help-panel').toggleClass('deck-help-visible')

$('.deck-toc-button').click -> $('.deck-toc-panel').toggleClass('show')
fixLocalLinks('.deck-toc-panel', false)
      
$(window).on 'touchstart', (event) ->
  window.touchParser.touchstart(event)
$(window).on 'touchend', (event) ->
  window.touchParser.touchend(event)
$(window).on 'touchTap', (event) ->
  window.touchPanel.tap(event)

# not figured out behavior on resize. Resize event triggerred twice on
# tablet orientation change. Also nasty jiggery behavior on ipad. So
# disabled for now
# 
# $(window).resize ->
#   #alert "starting resize"
#   window.rescaleViewport()

$(document).ready ->
  # handy items for debugging
  #meta = -> document.querySelector("meta[name=viewport]")
  #vc = -> if meta()? then meta()['content'] else "no meta tag"
  
  window.rescaleViewport()
