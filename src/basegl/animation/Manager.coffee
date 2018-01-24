require("modulereg").registerModule __filename, (require __filename)


########################
### AnimationManager ###
########################

export class AnimationManager
  constructor: () ->
    @fpsNative              = 120
    @fpsLimit               = null
    @maxMissingFrames       = 100

    @constantRateAnimations = new Set
    @everyDrawAnimations    = new Set
    @reset()

    window.addEventListener 'visibilitychange', () =>
       if document.visibilityState == 'visible' then @reset()
       else @_running = false

  start: () ->
    requestAnimationFrame @onFrame

  reset: () =>
    @_running          = true
    @_lastTime         = null
    @_missingFrames    = 0

  onFrame: (time) =>
    if not @_running  then return
    if not @_lastTime then @_lastTime = time
    timeDiff = time - @_lastTime

    if @fpsLimit
      fps = 1000/timeDiff
      if fps > (@fpsLimit + 1)
        requestAnimationFrame @onFrame
        return

    @_lastTime = time
    @_missingFrames += @fpsNative * timeDiff / 1000
    @_missingFrames = Math.min @_missingFrames, @maxMissingFrames

    while @_missingFrames >= 1
      @_missingFrames -= 1
      for f from @constantRateAnimations
        f(time)

    for f from @everyDrawAnimations
      f(time)

    requestAnimationFrame @onFrame


  addConstantRateAnimation: (f) -> @constantRateAnimations.add f
  addEveryDrawAnimation:    (f) -> @everyDrawAnimations.add    f

  removeEveryDrawAnimation:    (f) -> @everyDrawAnimations.delete    f
  removeConstantRateAnimation: (f) -> @constantRateAnimations.delete f



export animationManager = new AnimationManager
animationManager.start()
