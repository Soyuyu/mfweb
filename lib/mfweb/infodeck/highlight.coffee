class HighlightPanel
  constructor: (id, slideID, initialPositionClass) ->
    @id = id
    @slideID = slideID
    @position = initialPositionClass
    HighlightPanel.panels[@id] = this
    $('#' + @slideID).append("<div id = #{@id} class = 'highlight-panel #{@position}'/>")
    @element = $('#' + id)
     
  @panels: {}
  @clearAll: ->
    $('#deck-container .highlight-panel').remove()

  @get: (id) -> @panels[id]


  move: (cssClass) ->
    @element.removeClass(@position)
    @position = cssClass
    @element.addClass(@position)

  fadeOut: -> @element.fadeOut()
  fadeIn:  -> @element.fadeIn()
  hide:    -> @element.hide()
  show:    -> @element.show()
  remove: ->
    @element.remove()
    HighlightPanel.panels[@id] = undefined

window.HighlightPanel = HighlightPanel

class HighlightSequence
  currentState: undefined
  panel: undefined

  constructor: (slideID, states...) ->
    @slideID = slideID
    @states = states
    

  description_selector: ->
    '#' + @slideID + ' .highlight-description.' + @currentState

  move: (newState) ->
    $(@description_selector()).fadeOut()
    @currentState = newState
    @panel.move(@currentState)
    $(@description_selector()).fadeIn()

  setup: (state) ->
    @panel?.remove()
    @panel = new HighlightPanel(@slideID + '-hp', @slideID, "")
    @hide()
    @currentState = state
    @panel.move(state)

  fadeIn: ->
    $(@description_selector()).fadeIn()
    @panel.fadeIn()

  fadeOut: ->
    $(@description_selector()).fadeOut()
    @panel.fadeOut()

  show: ->
    $(@description_selector()).show()
    @panel.show()
    
  hide: ->
    $('#' + @slideID + ' .highlight-description').hide()
    @panel?.hide() 
  
  setupAtStart: ->
    @setup(@states[0])
    this

  setupAtEnd: ->
    @setup(@states[@states.length - 1])
    this

  state_index: -> @states.indexOf(@currentState)

  forwards: ->
    @move(@states[@state_index() + 1])
  backwards: ->
    @move(@states[@state_index() - 1])
  setup_forwards: -> 
  setup_backwards: ->

window.HighlightSequence = HighlightSequence