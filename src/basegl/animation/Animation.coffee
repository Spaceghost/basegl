require("modulereg").registerModule __filename, (require __filename)


import {animationManager} from 'basegl/animation/Manager'
import * as Property      from 'basegl/object/Property'
import * as Easing        from 'basegl/animation/Easing'


#################
### Animation ###
#################

export class Animation
  @defaultConfig =
    easing:      Easing.linear
    duration:    1
    startVal:    0
    endVal:      1
    time:        0
    onUpdate:    () ->
    onBegan:     () ->
    onCompleted: () ->
    onPaused:    () ->

  constructor: (config) ->
    Property.mergeMut @, (Property.merge Animation.defaultConfig, config)
    @step = 1 / (animationManager.fpsNative * @duration)

  start: () ->
    animationManager.addConstantRateAnimation @.onEveryFrame
    @onBegan()

  onEveryFrame: () =>
    @time += @step
    if @time >= 1
      @time = 1
      @cancel()
      @onCompleted()
    else if @time <= 0
      @time = 0
      @cancel()
      @onCompleted()
    @onUpdate @time, @

  reverse: () ->
    @step = -@step

  inverse: () ->
    @time = 1-@time
    @reverse()

  cancel: () -> animationManager.removeConstantRateAnimation @.onEveryFrame
  pause:  () -> @cancel(); @onPaused()



export create = (args...) -> new Animation args...
