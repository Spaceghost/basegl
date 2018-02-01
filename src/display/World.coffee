import * as Property from 'basegl/object/Property'
import * as Font     from 'basegl/display/text/Font'


export class World
  constructor: () ->
    @scenes          = new Set
    @offscreenScenes = new Set
    @activeScene     = null
    @fontManager     = Font.manager()

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

export world = Property.consAlias World
