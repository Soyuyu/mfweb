class LoadingSlide

  constructor: (uri) ->
    @_gettingDom = if uri then $.get(uri) else $.Deferred()
    @domLoading = $.Deferred()
    @_gettingDom.done (data) => @domLoading.resolve(data)
    @_gettingDom.fail (data) => @domLoading.reject(data)    
    @imagesLoading = $.Deferred()
    @_imagesLoadingCombiner = undefined
    @_all = $.when(@domLoading, @imagesLoading)

  @newResolved = ->
    result = new LoadingSlide()
    result.resolve()
    return result

  promise: -> @_all.promise()
  state:   -> @_all.state()
  always: (func) -> @_all.always(func)
  done:   (func) -> @_all.done(func)
  then:   (func) -> @always(func)
  fail:   (func) -> @_all.fail(func)

  reject: ->
    @imagesLoading.reject()
    @domLoading.reject()

  resolve: ->
    @imagesLoading.resolve()
    @domLoading.resolve()
    


  registerImages: (images) ->
    @_imagesLoadingCombiner = $.Deferred()
    imgPromises = []    
    registerImg = (img) =>
      $img = $(img)
      unless @isTrackingImage($img)
        deferredImg = $.Deferred()
        imgPromises.push(deferredImg)
        $img.load ->
          deferredImg.resolve()
    registerImg(i) for i in images
    $.when(imgPromises...).done =>
      @_imagesLoadingCombiner.resolve()
    @_imagesLoadingCombiner.done => @imagesLoading.resolve()
    @_imagesLoadingCombiner.fail => @imagesLoading.reject()

    # the indirection of separating _imagesLoadingCombiner from
    # imagesLoading may not be needed, but I think it's helpful to
    # think about for the moment. Can maybe use a pipe for this, still
    # thinking on that

  isTrackingImage: (img) ->
    return img.attr('src').match("^http://www.assoc-amazon.com")

window.LoadingSlide = LoadingSlide