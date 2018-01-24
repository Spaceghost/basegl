require("modulereg").registerModule __filename, (require __filename)

import {define, mixin, configure, configureLazy, params, lazy, configure2, Composition} from 'basegl/object/Property'


export class World
  constructor: () ->
    @scenes          = new Set
    @offscreenScenes = new Set
    @activeScene     = null

    @_initMouseSceneRedirection()

  _initMouseSceneRedirection: () ->
    document.addEventListener 'keydown', (e) =>
      @activeScene?.dispatchEvent e

  registerOffscreenScene: (s) ->
    @offscreenScenes.add s

  registerScene: (s) ->
    @scenes.add s
    s.domElement.addEventListener 'mouseover', (e) => @activeScene = s
    s.domElement.addEventListener 'mouseout',  (e) => @activeScene = null



export world = new World




# export class World2 extends Composition
#
#   @parameters
#     _canvas: null
#
#   init: () ->
#     @_initRenderer()
#
#   _initRenderer: () ->
#     if not @_canvas
#       @_canvas = document.createElementNS 'http://www.w3.org/1999/xhtml', 'canvas'
#       @canvas.style.display = 'block'
#     @_renderer = new THREE.WebGLRenderer {antialias: true, alpha:true, canvas:@canvas}
#
#
#
#
#   # constructor: () ->
#   #   @scenes          = new Set
#   #   @offscreenScenes = new Set
#   #   @activeScene     = null
#   #
#   #   @_initMouseSceneRedirection()
#
#   _initMouseSceneRedirection: () ->
#     document.addEventListener 'keydown', (e) =>
#       @activeScene?.dispatchEvent e
#
#   registerOffscreenScene: (s) ->
#     @offscreenScenes.add s
#
#   registerScene: (s) ->
#     @scenes.add s
#     s.domElement.addEventListener 'mouseover', (e) => @activeScene = s
#     s.domElement.addEventListener 'mouseout',  (e) => @activeScene = null
#
#
# export world2 = new World2
