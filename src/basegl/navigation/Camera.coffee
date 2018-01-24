require("modulereg").registerModule __filename, (require __filename)

import {DisplayObject}   from "basegl/display/DisplayObject"


export class GLCamera extends THREE.PerspectiveCamera
  constructor: (@camera, @scene) ->
    super 45, 1, 0.1, 1000000
    @_zoomFactor = 1
    @onSceneSizeChange()

  update: () -> @camera.update @

  onSceneSizeChange: () ->
    @aspect = @scene.width / @scene.height
    @updateProjectionMatrix()
    @camera.onSceneSizeChange @




export class Camera extends DisplayObject
  constructor: (@fov=45) ->
    super()
    @position.z = 1

  @getter 'zoomFactor', -> @position.z

  onSceneSizeChange: (glCamera) ->
    vFOV                 = @fov * Math.PI / 180
    glCamera._zoomFactor = glCamera.scene.height / (2 * Math.tan(vFOV/2))

  update: (glCamera) ->
    glCamera.position.x = @position.x + glCamera.scene.width/2
    glCamera.position.y = @position.y + glCamera.scene.height/2
    glCamera.position.z = @position.z * glCamera._zoomFactor
