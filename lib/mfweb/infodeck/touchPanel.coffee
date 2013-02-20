class TouchPanel
  constructor: ->
    @visible = false
    $('.deck-touch-panel .button.previous, .deck-touch-panel .button.next').width(100)
    $('.deck-touch-panel .button.first').click ->
      window.deck.goToFirst()
    $('.deck-touch-panel .button.last').click ->
      window.deck.goToLast()
    $('.deck-touch-panel .button.goto').click ->
      window.deck.toggleGoToPanel()

  _sideWidth: 100

  tap: (event) ->
    return if $(event.target).closest('.banner').length != 0
    if event.pageX < @_sideWidth
      window.deck.backwards()
    else if event.pageX > $(window).width() - @_sideWidth
      window.deck.forwards()
    else @toggleTouchPanel()

  toggleTouchPanel: ->
    $('.deck-touch-panel').toggle(500)


window.touchPanel = new TouchPanel