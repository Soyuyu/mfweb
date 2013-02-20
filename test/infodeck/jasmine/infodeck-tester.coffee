expectOneSlideWithID = (matcher, positionClass, expectedID) ->
  sel = $(".slide.#{positionClass}")
  if sel.length > 1
    matcher.message = -> "more than one #{positionClass} slide"
    return false
  else if sel.length == 0
    matcher.message = -> "no #{positionClass} slide"
    return false
  else if sel.first().attr('id') != expectedID
    matcher.message = ->
       "#{positionClass} slide is #{sel.first().attr('id')} but expecting #{expectedID}"
    return false
  else return true

expectNoSlide = (matcher, positionClass) ->
  sel = $(".slide.#{positionClass}")
  if sel.length > 1
    matcher.message = -> "#{sel.length} #{positionClass} slides but expected none"
    return false
  else if sel.length == 1
    matcher.message = ->
      "#{positionClass} slide #{sel.first().attr('id')} but expected none"
    return false
  else return true
  

expectSlideWithID = (matcher, positionClass, expectedID) ->
  if expectedID?
    expectOneSlideWithID(matcher, positionClass, expectedID)
  else
    expectNoSlide(matcher, positionClass)

matchSlides = (matcher, previousID, currentID, nextID) ->
  fullMessage = []
  result = true
  unless expectSlideWithID(matcher, 'previous', previousID)
    fullMessage.push(matcher.message())
    result = false
  unless expectOneSlideWithID(matcher, 'current', currentID)
    fullMessage.push(matcher.message())
    result = false
  unless expectSlideWithID(matcher, 'next', nextID)
    fullMessage.push(matcher.message())
    result = false
  if result && $(".slide").length > 3
    fullMessage.push("more than 3 slides present")
    result = false
  matcher.message = -> fullMessage.join()
  return result


waitForDeck = (spec) ->
  latch = -> window.deck.loading().state() != "pending"    
  spec.waitsFor latch, "loading deck", 500

forward = (spec) ->
  spec.runs -> window.deck.forwards()
  waitForDeck(spec)

backward = (spec) ->
  spec.runs -> window.deck.backwards()
  waitForDeck(spec)

enable_logger = ->
  window.deck.log = (msg) -> console.log msg; true

describe "infodeck object", ->
  
  beforeEach ->
    #console.log this.description
    @addMatchers 
      toHaveCurrent: (arg) ->
        expectOneSlideWithID(this, 'current', arg)
      toHaveNext: (arg) ->
        expectSlideWithID(this, 'next', arg)
      toHavePrevious: (arg) ->
        expectSlideWithID(this, 'previous', arg)
      toHaveSlides: (previous, current, next) ->
        matchSlides(this, previous, current, next)
      toHaveClass: (cssClass) ->
        this.actual.hasClass(cssClass)

    waitForDeck(this) if window.deck?
    runs ->    
      initialize_deck();

  describe "initial load", ->

    describe "if request uri includes hash fragment", ->
      beforeEach ->
        runs ->
          window.deck.location = -> {hash: "#begin"}
          window.deck.load()
        waitForDeck(this)
      
      it "loads correct current slide for hash", ->
        runs ->
          marker = $('.slide.current div.lede').attr('title')
          expect(marker).toMatch(/To understand/)
          expect().toHaveSlides('contents', 'begin', 'less')
          expect(window.deck.slideIndex).toBe(2)
      
      it "sets slide index", ->
          expect(window.deck.slideIndex).toBe(2)

    describe "if request has no hash", ->
      beforeEach ->
        runs -> window.deck.load()
        waitForDeck(this)
        
      it "load will load first slide", ->
        runs ->
          expect($('#deck-container #cover').length).toBe(1)
          marker = $('#deck-container #cover div.lede').attr('title')
          expect(marker).toBe("Tests for Jasmine to work on")
          expect().toHaveSlides(undefined, 'cover', 'contents')

      it "slide index is 0", ->
        runs ->
          expect(window.deck.slideIndex).toBe(0)

      it "removes loading message", ->
        runs ->
          expect($('.deck-loading-message').length).toBe(0)


    it "will pre-load next slide", ->
      runs -> window.deck.load()
      waitsFor((-> window.deck.loadingNext.state() == "resolved"), "loading next", 500)
      runs ->
        expect($('.slide.next').length).toBe(1)
        element = $('#deck-container .next div.lede')
        marker = element.attr('title')
        expect(element.length).not.toBe(0)
        expect(marker).toBe("Our agenda")

    it "does not try to pre-load next slide when on last slide", ->
      window.deck.location = -> {hash: "#what"}
      runs -> window.deck.load()
      waitsFor((-> window.deck.loadingCurrent.state() == "resolved"), "loading next", 500)
      runs ->
        expect().toHaveNext(undefined)
        
    it "will pre-load previous slide", ->
      window.deck.location = -> {hash: "#contents"}
      runs -> window.deck.load()
      waitsFor((-> window.deck.loadingPrevious.state() == "resolved"), "loading previous", 500)
      runs ->
        expect().toHavePrevious('cover')

    it "does not try to pre-load previous slide when on first slide", ->
      runs -> window.deck.load()
      waitsFor((-> window.deck.loadingCurrent.state() == "resolved"), "loading next", 500)
      runs ->
        expect().toHavePrevious(undefined)

  describe "when advancing slides", ->      

    it "goes to next slide, pre-load following slide", ->
      runs ->
        window.deck.location = -> {hash: "#contents"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('cover', 'contents', 'begin')
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')

    it "ignores requests for next slide when at end", ->
      runs ->
        window.deck.location = -> {hash: "#what"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('less', 'what', undefined)

    it "ignores requests for next slide when spinning", ->
      runs ->
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
        window.deck.forwards()
        window.deck.forwards()
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')

  describe "when going back with slides", ->      

    it "goes to previous slide, pre-load prior slide", ->
      runs ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('cover', 'contents', 'begin')

    it "ignores requests for previous slide when at start", ->
      runs ->
        window.deck.location = -> {hash: "#cover"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides(undefined, 'cover', 'contents')

    it "ignores requests for previous slide when spinning", ->
      runs ->
        window.deck.location = -> {hash: "#less"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
        window.deck.backwards()
        window.deck.backwards()
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('cover', 'contents', 'begin')

  describe "going to an arbitrary slide", ->
    beforeEach ->
      runs ->
        window.deck.load()
      waitForDeck(this)
      
    
    it "loads correct slides", ->
      runs ->
        window.deck.goToSlide(3)
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', "less")

    it "goes to last if number is too big", ->
      runs ->
        window.deck.goToSlide(5)
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('less', 'what', undefined)

    it "goes to a slide, then backwards", ->
      runs ->
        window.deck.goToSlide(3)
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('cover', 'contents', 'begin')
     
        

  describe "edge cases when starting at ends", ->
    it "load last page, should be back and forward", ->
      runs ->
        window.deck.location = -> {hash: "#what"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('less', 'what', undefined)

    it "load first page, should be forward and back", ->
      runs ->
        window.deck.load()
      waitForDeck(this)
      forward(this)
      backward this
      runs ->
        expect().toHaveSlides(undefined, 'cover', 'contents')

  xdescribe "an edge case for loading", ->

    # not sure what's happening here. Can't reproduce in slowed browser so
    # letting it slide for a bit

    it "this one fails", ->
        runs ->
          window.deck.location = -> {hash: "#begin"}
          window.deck.load()
        waitForDeck(this)
        runs ->
          window.deck.log = (message) -> console.log message
          window.deck.backwards()
          window.deck.forwards()
        waitForDeck(this)
        runs ->
          expect().toHaveSlides('contents', 'begin', 'less')

    it "this one passes", ->
        runs ->
          window.deck.location = -> {hash: "#contents"}
          window.deck.load()
        waitForDeck(this)
        runs ->
          window.deck.backwards()
          window.deck.forwards()
        waitForDeck(this)
        runs ->
          expect().toHaveSlides('cover', 'contents', 'begin')

  describe "loading builds", ->
    beforeEach ->
      runs ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()
      waitForDeck(this)

    it "has build collection present when loaded", ->
      runs ->
        expect(deck._data.builds['begin']).toBeDefined()
    it "has setup build present when loaded", ->
      runs ->
        expect(deck._data.builds['begin']['setupBuild']).toBeDefined()

  describe "handling builds", ->

    it "performs setup build on direct navigation", ->
      runs ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        expect($('.insert-text')).toHaveClass('hidden')

  
    it "performs setup build on forward", ->
      runs ->
        window.deck.location = -> {hash: "#contents"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect($('.insert-text')).toHaveClass('hidden')

        
    it "performs backward setup build on bacwards", ->
      runs ->
        window.deck.location = -> {hash: "#less"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect($('.insert-text')).not.toHaveClass('hidden')
        expect($('.create-arrow')).toHaveClass('hidden')
        expect($('.create-text')).toHaveClass('charred')

      
    it "goes forwards with a build", ->
      runs ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')
        expect($('.insert-text')).not.toHaveClass('hidden')
        expect($('.create-arrow')).toHaveClass('hidden')
        expect($('.create-text')).toHaveClass('charred')
      
    it "goes forwards with a build and forward to next slide", ->
      runs ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      waitForDeck(this)
      runs ->
        window.deck.forwards()
      runs ->
        expect().toHaveSlides('begin', 'less', undefined)
      
    it "goes backwards into a slide with a build", ->
      runs ->
        window.deck.location = -> {hash: "#less"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')
        expect($('.insert-text')).not.toHaveClass('hidden')
        expect($('.create-arrow')).toHaveClass('hidden')
        expect($('.create-text')).toHaveClass('charred')
        
     it "goes backwards undoing a build", ->
      runs ->
        window.deck.location = -> {hash: "#less"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        window.deck.backwards()
      waitForDeck(this)
      runs ->
        expect().toHaveSlides('contents', 'begin', 'less')
        expect($('.insert-text')).toHaveClass('hidden')
        expect($('.create-text')).not.toHaveClass('charred')

  it "executes an immediate build", ->
      runs ->
        window.deck.location = -> {hash: "#what"}
        window.deck.load()
      waitForDeck(this)
      runs ->
        $('.deck-curtain').on "transitionend webkitTransitionEnd oTransitionEnd", ->
          expect($('g.what')).toHaveClass('charred')
          expect($('g.when')).not.toHaveClass('hidden')

  it "skips backwards then forwards to initial state of slide", ->
    runs ->
      window.deck.location = -> {hash: "#less"}
      window.deck.load()
    waitForDeck(this)
    runs -> window.deck.skipBackwards()
    waitForDeck(this)
    runs -> window.deck.skipBackwards()
    waitForDeck(this)
    runs -> window.deck.forwards()
    waitForDeck(this)
    runs ->
      expect().toHaveSlides('contents', 'begin', 'less')
      expect($('.insert-text')).toHaveClass('hidden')

  it "skips forwards then backwards to final state of slide", ->
    runs ->
      window.deck.location = -> {hash: "#contents"}
      window.deck.load()
    waitForDeck(this)
    runs -> window.deck.skipForwards()
    waitForDeck(this)
    runs -> window.deck.skipForwards()
    waitForDeck(this)
    runs -> window.deck.backwards()
    waitForDeck(this)
    runs ->
      expect().toHaveSlides('contents', 'begin', 'less')
      expect($('.insert-text')).not.toHaveClass('hidden')
      

      

      

 
        

  
       
        
        


    

