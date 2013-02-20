$(document).ready ->
  $('.deck-next-link').click  ->
    deck.forwards()
  $('.deck-prev-link').click  ->
    deck.backwards()
  $('.deck-help').click ->
    $('.deck-help-panel').toggleClass('deck-help-visible')
  $('.deck-status').click  ->
    deck.toggleGoToPanel()
  $('.deck-permalink').click (ev) ->
    history.pushState('','',deck.permalink())
  $('#deck-container').on 'deck-becameCurrent', ->
    $('.deck-prev-link').toggleClass('deck-nav-disabled', deck.currentIsFirst())
    $('.deck-next-link').toggleClass('deck-nav-disabled', deck.currentIsLast())
    $('.deck-status-current').text(deck.currentSlideNumber())
    $('.deck-status-total').text(deck.length())
    $('a.deck-permalink').attr('href', deck.permalink())
    