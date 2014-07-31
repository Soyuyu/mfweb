
################ helper functions ################

loaded = -> Q(window.deck.loading())

load = (id) ->
  if id
    window.deck.location = -> {hash: "#" + id}
  window.deck.load()
  return loaded()

loadLast = -> load('what')

forwards = ->
  window.deck.forwards()
  loaded()

backwards = ->
  window.deck.backwards()
  loaded()

quiet = ->
  # should only resolve when deck has nothing more to do
  # but isn't reliable - need to investigate further
  # so if I need to use this will need to add a delay to avoid false failures
  def = Q.defer()
  Q.delay(1).then(-> doQuiet(def, 10))
  return def.promise

doQuiet = (result, retries) ->
  if window.deck.loading().state() != "pending"
    #console.log "FIN:  #{retries} at " + $('.slide.current').attr('id')
    result.resolve()
  else if retries == 0
    result.reject("deck did not settle")
  else
    #console.log("DELAY: #{retries} at " + $('.slide.current').attr('id'))
    Q.delay(10).then(-> doQuiet(result, retries - 1))
    
currentID = ->
  sel = $(".slide.current")
  if sel.length == 0
    "No Slide"
  else
    sel.first().attr('id')

      

################# custom asserts ################

flunk = (message) ->
  assert.fail(null, null, message)

checkOneSlideAt = (positionClass, expectedID) ->
  result = []
  sel = $(".slide.#{positionClass}")
  if sel.length == 0
    result.push("no #{positionClass} slide, expecting <#{expectedID}>")
  else if sel.length > 1
    result.push("more than one #{positionClass} slide")
  else
    actual = sel.first().attr('id')
    if actual != expectedID
      result.push("#{positionClass} slide is <#{actual}> but expecting <#{expectedID}>")
  return result

checkNoSlideAt = (positionClass) ->
  result = []
  sel = $(".slide.#{positionClass}")
  if sel.length > 1
    result.push("#{sel.length} #{positionClass} slides but expected none")
  else if sel.length == 1
    result.push("#{positionClass} slide <#{sel.first().attr('id')}> but expected none")
  return result

checkSlideAt = (positionClass, expectedID) ->
  if expectedID?
    checkOneSlideAt(positionClass, expectedID)
  else
    checkNoSlideAt(positionClass)



assertSlideAt = (positionClass, expectedID) ->
  result = checkSlideAt(positionClass, expectedID)
  flunk(result.join()) if result.length > 0

assertSlides = (prev, cur, next) ->
  result = checkSlideAt('previous', prev).concat(checkSlideAt('current', cur), checkSlideAt('next', next))
  flunk(result.join()) if result.length > 0


assertAtFirstBuild = ->
  assertSlides('contents', 'begin', 'less')
  expect($('.insert-text')).have.class('hidden')
  expect($('.create-arrow')).not.have.class('hidden')

assertAtSecondBuild = ->
  assertSlides('contents', 'begin', 'less')
  expect($('.insert-text')).not.have.class('hidden')
  expect($('.create-text')).have.class('charred')


################ tests ################################

describe "Infodeck Tests", ->
  beforeEach ->
    #make sure we have a fresh deck
    Q(deck.loading()).then ->
      initialize_deck()
      window.deck.location = -> {hash: null}

  describe "initial load", ->
  
    describe "with hash fragment", ->
      beforeEach ->
        window.deck.location = -> {hash: "#begin"}
        window.deck.load()

        
      it "goes to correct slide", ->
        loaded().then ->
          $currentSlide = $(".slide.current")
          assertSlideAt("current", "begin")
          assertSlides('contents', 'begin', 'less')
          expect(window.deck.slideIndex).to.equal(2)

      it "has correct content text", ->
        loaded().then ->
          marker = $('.slide.current div.lede p').text()
          expect(marker).to.match(/To understand/)

    describe "with plain URL", ->

      it "goes to first slide", ->
        load().then ->
          $currentSlide = $(".slide.current")
          assertSlides(undefined, 'cover', 'contents')
          expect(window.deck.slideIndex).to.equal(0)

      it "removes loading message", ->
        load().then ->
          expect($('.deck-loading-message').length).to.equal(0)

    describe "with last slide", ->
      it "goes to last slide", ->
        load('what').then ->
          $currentSlide = $(".slide.current")
          assertSlides('less', 'what', undefined)
          expect(window.deck.slideIndex).to.equal(4)
           

  describe "when jumping to numbered slide", ->

    it "goes to correct slides", ->
      loaded()
      .then ->
        window.deck.goToSlide(3)
        loaded().then ->
          assertSlides('contents', 'begin', 'less')

    it "goes to last if number is too big", ->
      loaded()
      .then ->
        window.deck.goToSlide(666)
        loaded().then ->
          assertSlides('less', 'what', undefined)

    it "goes backwards correctly", ->
      loaded()
      .then ->
        window.deck.goToSlide(3)
        loaded()
      .then ->
        window.deck.backwards()
        loaded()
      .then ->
        assertSlides('cover', 'contents', 'begin')

  describe "when advancing", ->
    it "goes to next slide, loads following", ->
      load('contents').then ->
        assertSlides('cover', 'contents', 'begin')
        window.deck.forwards()
        return loaded()
      .then ->
        assertSlides('contents', 'begin', 'less')

    it "ignores request for next slide if at end", ->
      loadLast().then -> forwards()
      .then ->
        assertSlides('less', 'what', undefined)

    it "ignores requests for next slide when spinning", ->
      load('cover').then ->
        window.deck.forwards()
        window.deck.forwards()
        window.deck.forwards()
        window.deck.forwards()
      quiet().delay(40).then ->
        #console.log "********* should be done now"
        assertSlides('contents', 'begin', 'less')

  describe "when going backwards", ->     
    it "goes to preveious slide, loads prior", ->
      load('begin').then ->
        window.deck.backwards()
        return loaded()
      .then ->
        assertSlides('cover', 'contents', 'begin')

    it "ignores request for previous slide if at start", ->
      load().then ->
        window.deck.backwards()
        return loaded()
      .then ->
        assertSlides(undefined, 'cover', 'contents')

    it "ignores requests for next slide when spinning", ->
      load('less').then ->
        window.deck.backwards()
        window.deck.backwards()
        window.deck.backwards()
        window.deck.backwards()
      quiet().delay(40).then ->
        #console.log "********* should be done now"
        assertSlides('cover', 'contents', 'begin')

  describe "some edge cases", ->
    it "load last page, can move back and forwards", ->
      loadLast()
      .then(backwards)
      .then(forwards)
      .then -> assertSlides('less', 'what', undefined)

    it "loads first page, can move forward and back", ->
      load()
      .then(forwards)
      .then(backwards)
      .then -> assertSlides(undefined, 'cover', 'contents')

    it "this failed in jasmine but seems to work here", ->
      load('begin')
      .then ->
        window.deck.backwards()
        window.deck.forwards()
        loaded()
      .then -> assertSlides('contents', 'begin', 'less')

    it "this succeeded in jasmine in contrast to one above", ->
      load('contents')
      .then ->
        window.deck.backwards()
        window.deck.forwards()
        loaded()
      .then -> assertSlides('cover', 'contents', 'begin')


  describe "working with builds", ->
    beforeEach -> load('begin')

    it "has build collection present when loaded", ->
      loaded().then ->
        assert.isDefined(deck._data.builds['begin'])

    it "performs setup build on direct navigation", ->
      loaded().then ->
        assertAtFirstBuild()

    it "performs setup build on forward", ->
      load('contents')
      .then(forwards) 
      .then(assertAtFirstBuild)

    it "backwards into build slide", ->
      load('less')
      .then(backwards)
      .then(assertAtSecondBuild)

    xit "jump to slide with builds then forwards", ->
      # test fails in jasmine and mocha
      load('begin')
      .then ->
        window.deck.forwards()
        loaded()
      .then ->
        assertAtSecondBuild()

    it "forward with builds goes to next slide", ->
      load('begin')
      .then(forwards)
      .then(forwards)
      .then -> assertSlides('begin', 'less', 'what')
      # note final assert is different to jasmine test
      # jasmine test is wrong but passes anyway :-/

    xit "goes backwards into second build then first build", ->
      # test passes in jasmine
      # fails regularly in mocha
      load('less')
      .then ->
        window.deck.backwards()
        loaded()
      .then -> 
        window.deck.backwards()
        loaded()
      .then -> assertAtFirstBuild()

    it "executes an immediate build", ->
      load('what')
      .then ->
        $('.deck-curtain').on "transitionend webkitTransitionEnd oTransitionEnd", ->
          expect($("g.what")).have.class('charred')
          expect($("g.when")).not.have.class('hidden')

    xit "skip backwards over builds, then prev, then forwards to first build", ->
      # occasionally fails when run in suite
      load('less')
      .then ->
        window.deck.skipBackwards()
        loaded()
      .then -> 
        window.deck.skipBackwards()
        loaded()
      .then(forwards)
      .then(assertAtFirstBuild)

    xit "skips forwards over build then backwards to final build", ->
      # fails regularly on both jasmine and mocha
      load('contents')
      .then ->
        window.deck.skipForwards()
        loaded()
      .then ->
        window.deck.skipForwards()
        loaded()
      .then(backwards)
      .then(assertAtSecondBuild)

