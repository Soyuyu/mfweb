class Infodeck

  constructor: (data) ->
    @contents = data?.contents
    @_data = {}
    @_data.builds = {}
    @loadingPrevious = LoadingSlide.newResolved()
    @loadingNext = LoadingSlide.newResolved()
    @loadingCurrent = LoadingSlide.newResolved()

  log: (message) ->
    # console.log(message)
    false

  resolvedPromise: ->
    $.Deferred().resolve()
        
  load: ->
    @initializeUI()
    @showSlideIndex(@indexForHash(@location().hash))

  loading: ->
    $.when(@loadingCurrent, @loadingNext, @loadingPrevious)

  loadCurrentSlide: ->
    @loadingCurrent =  new LoadingSlide(@currentURI())
    if $('#deck-container slide').length > 0
      console.warn "container should have no slides"
    @loadingCurrent.domLoading.done (data) =>
      slide = $(data)
      @attachSlide(slide, 'current', @loadingCurrent)
      @removeLoadingMessage()
      @busy(true)
    @loadingCurrent.domLoading.fail =>
      console.log ("error reading current slide #{@currentURI()}")

  removeLoadingMessage: ->
    $('.deck-loading-message').remove()

  attachSlide: (data, positionClass, completing) ->
    slide = $(data)
    if @expectedID(positionClass) != slide.attr('id')
      console.log "mismatch attach"
      return
    if $(".slide." + positionClass).length > 0
      if slide.attr('id') != $(".slide." + positionClass).first.id
        console.warn "trying to attach non duplicate to same position"
      else
        return
    
    slide.addClass(positionClass)
    $('#deck-container').append(slide)
    @runSetupBuild(slide, positionClass)
    completing.registerImages $('img', slide)
    completing.imagesLoading.done =>
      @busy(false)
      @log "resolved " + positionClass
    @log "done attach " + positionClass

  expectedID: (positionClass) ->
    switch positionClass
      when 'current'  then @idForURI(@currentURI())
      when 'next'     then @idForURI(@nextURI())
      when 'previous' then @idForURI(@previousURI())

  runSetupBuild: (slide, positionClass) ->
    switch positionClass
      when 'current', 'next'
        @buildsFor(slide)?.setupBuild?.forwards()
      when 'previous'
        @buildsFor(slide)?.setupBuild?.backwards()
      else console.warn "unknown positionClass: " + positionClass
    
  loadNextSlide: ->
    if @currentIsLast()
      @loadingNext = window.LoadingSlide.newResolved()
    else
      @loadingNext = new LoadingSlide(@nextURI())
      @loadingNext.domLoading.done (data) =>
        @attachSlide(data, 'next', @loadingNext)
      

  loadPreviousSlide: ->
    if @currentIsFirst()
      @loadingPrevious = window.LoadingSlide.newResolved()
    else
      @loadingPrevious = new LoadingSlide(@previousURI())
      @loadingPrevious.domLoading.done (data) =>
        @attachSlide(data, 'previous', @loadingPrevious)
      
  idForURI: (uri) -> uri.slice(0,-5)

  nextURI: -> @contents[@slideIndex + 1]['uri']
  previousURI: -> @contents[@slideIndex - 1]['uri']
  currentURI: ->  @contents[@slideIndex]['uri']

  permalink: ->
    '#' + @currentSlide().attr('id')

  isQuiet: ->
    @loadingCurrent.state() != 'pending' &&
      @loadingNext.state() != 'pending' &&
      @loadingPrevious.state() != 'pending' 
      
  location: ->
    window.location

  indexForHash: (hash) ->
    if hash
      (i for entry, i in @contents when entry['uri'] == @uriForHash(hash))[0]
    else 0

  uriForHash: (hash) -> hash.slice(1) + ".html"

  currentIsLast: -> @slideIndex + 1 == @contents.length
  currentIsFirst: -> @slideIndex == 0

  nextSlide:     -> $('.slide.next').first()
  currentSlide:  -> $('.slide.current').first()
  previousSlide: -> $('.slide.previous').first()
  length: -> @contents.length
  currentSlideNumber: ->
    @slideIndex + 1

  dropCurtain: ->
    $('#deck-container').append("<div class = 'deck-curtain'/>")
    $('.deck-curtain').addClass('dropped')
    
  raiseCurtain: (func) ->
    $('.deck-curtain').removeClass('dropped')
    $('.deck-curtain').on "transitionend webkitTransitionEnd oTransitionEnd", ->
      $('.deck-curtain').remove()
      func()

  buildsFor: (aSlide) ->
    @_data.builds[aSlide.attr('id')]

  showSlideIndex: (ix) ->
    $('.init').hide()
    @dropCurtain()
    $('#deck-container .slide').remove()
    @slideIndex = ix
    @_data.buildIndex = 0
    @hideTableOfContents();
    @loadCurrentSlide()
    @loadNextSlide()
    @loadPreviousSlide()
    @loadingCurrent.done =>
      @raiseCurtain =>
        @currentSlide().trigger('deck-becameCurrent')
        @buildsFor(@currentSlide())?.immediateBuild?.forwards()
      

  showNextSlide: ->
    @trimAddressBar()
    @loadingPrevious.reject()
    unless @isQuiet()
      console.warn("show next slide while loads are pending")
    wasNext = @nextSlide()
    wasCurrent = @currentSlide()
    @loadingPrevious.domLoading.always ->
      $('.slide.previous').remove()
    @slideIndex += 1
    @_data.buildIndex = 0
    wasNext.removeClass('next').addClass('current')
    wasCurrent.removeClass('current').addClass('previous')
    @log "-> " + @currentURI()
    $('.current').on "transitionend webkitTransitionEnd oTransitionEnd", =>
      @currentSlide().trigger('deck-becameCurrent')
      @buildsFor(@currentSlide())?.immediateBuild?.forwards()
    @loadNextSlide()

  showPreviousSlide: ->
    @trimAddressBar()
    @loadingNext.reject()
    unless @isQuiet()
      console.warn("show previous slide while loads are pending")
    wasCurrent = @currentSlide()
    wasPrevious = @previousSlide()
    @buildsFor(@currentSlide())?.immediateBuild?.backwards()
    @loadingNext.domLoading.always ->
      $('.slide.next').remove()
    @slideIndex -= 1
    @_data.buildIndex = @buildsFor(@previousSlide())?.length() || 0
    wasPrevious.removeClass('previous').addClass('current')
    wasCurrent.removeClass('current').addClass('next')
    @currentSlide().trigger('deck-becameCurrent')
    @log "<- " + @currentURI()
    @loadPreviousSlide()

  baseLocation: ->
    'http://' + window.location.host + window.location.pathname

  trimAddressBar: ->
    return if window.location.hash == ""
    window.history.replaceState '', '', @baseLocation() 

  busy: (bool) ->
      $('.slide.current').spin(bool)
      @_isBusy = bool
      #@log "busy set " + bool

  requestNextSlide: ->
    return if @currentIsLast()
    return if @_isBusy
    @log "next requested " + @nextURI()
    if @loadingNext.state() == "pending"
      @busy(true)
    @loadingNext.always =>
      @busy(false)
      @showNextSlide()


  requestPreviousSlide: ->
    return if @currentIsFirst()
    return if @_isBusy
    @log "prev requested " + @previousURI()
    if @loadingPrevious.state() == "pending"
      @busy(true)
    @loadingPrevious.always =>
      @busy(false)
      @showPreviousSlide()

  goToSlide: (num) ->
    @trimAddressBar()
    @log "requested go to slide #{num}"
    if num > @length()
      @goToLast()
    else if num < 1
      @goToFirst()
    else
      if @loading().state() == "pending"
        @busy(true)
      @loading().always =>
        @busy(false)
        @showSlideIndex(num - 1)

  goToHash: (hash) ->
    @goToSlide(@indexForHash(hash) + 1)
  
  goToFirst: ->
    @goToSlide 1

  goToLast: ->
    @goToSlide @length()

  toggleTableOfContents: ->
    $('.deck-toc-panel').toggleClass('show')

  hideTableOfContents: ->
    $('.deck-toc-panel').removeClass('show')


  $goToField: ->
    $('.deck-goto-panel .deck-goto-input')

  $goToPanel: ->
    $('.deck-goto-panel')

  toggleGoToPanel: ->
    this.$goToPanel().toggleClass('show')
    if this.$goToPanel().hasClass('show')
      this.$goToField().focus()
    else
      this.$goToField().blur()
      this.$goToField().val('')

  initializeGoToPanel: ->
    this.$goToField().keyup (event) =>
      this.$goToField().val(this.$goToField().val().replace(/[^0-9]/g,''))
      @toggleGoToPanel() if event.which == 71  
      event.stopPropagation()
    this.$goToPanel().submit (event) =>
        @goToSlide this.$goToField().val()
        @toggleGoToPanel()
        return false;

  forwards: ->
    if @buildsFor(@currentSlide())?
      if @_data.buildIndex == @buildsFor(@currentSlide()).length()
        @requestNextSlide()
      else
        @buildsFor(@currentSlide()).sequence[@_data.buildIndex].forwards()
        @_data.buildIndex += 1
    else
      @requestNextSlide() 

  backwards: ->
    if @buildsFor(@currentSlide())?
      if @_data.buildIndex == 0
        @requestPreviousSlide()
      else
        @_data.buildIndex -= 1
        @buildsFor(@currentSlide()).sequence[@_data.buildIndex].backwards()
    else
      @requestPreviousSlide()

  toggleTouchPanel: ->
    window.touchPanel.toggleTouchPanel()

  skipForwards: ->
    @requestNextSlide()
    @loadingNext.always =>
      @runSetupBuild($('.slide.previous'), 'previous')

  skipBackwards: ->
    @requestPreviousSlide()
    @loadingPrevious.always =>
      @runSetupBuild($('.slide.next'), 'next')


  bindKeyboardEvents: ->
    $(document).keyup (event) =>
      map =
        '8' : 'backwards'   # backspace
        '32' : 'forwards'    # space
        '33' : 'skipBackwards'    # page-up
        '34' : 'skipForwards' # page-down
        '35' : 'goToLast'    # end
        '36' : 'goToFirst'   # home
        '37' : 'backwards'   # left-arrow
        '38' : 'skipBackwards'    #up-arrow
        '39' : 'forwards'    # right-arrow
        '40' : 'skipForwards'  #down-arrow
        '67' : 'toggleTableOfContents'     # c
        '71' : 'toggleGoToPanel'  # g
        '74' : 'backwards'         # j
        '75' : 'forwards'         # k
        '80' : 'toggleTouchPanel' # p
      if map[event.which] then this[map[event.which]].call(this)

  initializeUI: ->
    @bindKeyboardEvents()
    @initializeGoToPanel()

  addBuild: (slideID, aBuild) ->
    @_data.builds[slideID] ?= new BuildCollection()
    @_data.builds[slideID].addSequence(aBuild)

  addSetupBuild: (slideID, aBuild) ->
    @_data.builds[slideID] ?= new BuildCollection()
    @_data.builds[slideID].addSetupBuild(aBuild)

  addImmediateBuild: (slideID, aBuild) ->
    @_data.builds[slideID] ?= new BuildCollection()
    @_data.builds[slideID].addImmediateBuild(aBuild)


class BuildCollection
  constructor: ->
    @sequence = []

  addSequence: (aBuild) ->
    @sequence.push(aBuild)

  addSetupBuild: (aBuild) ->
    @setupBuild = aBuild
  addImmediateBuild: (aBuild) ->
    @immediateBuild = aBuild
  length: ->
    @sequence.length

window.Infodeck = Infodeck

