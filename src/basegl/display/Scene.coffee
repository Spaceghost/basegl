require("modulereg").registerModule __filename, (require __filename)


import {DisplayObject, POINTER_EVENTS}    from 'basegl/display/DisplayObject'
import {ComponentGeometry, ComponentFamily, DRAW_BUFFER}    from 'basegl/display/Component'
import {Camera, GLCamera} from 'basegl/navigation/Camera'
import {animationManager} from 'basegl/animation/Manager'
import {world}            from 'basegl/display/World'
import {disableBubbling}  from 'basegl/event/EventDispatcher'
import {Shape}         from 'basegl/display/Shape'
import {IdxPool}          from 'container/Pool'
import {Stats}            from 'Stats'
import {setObjectProperty} from 'basegl/object/Property'

import * as Color from 'basegl/display/Color'
import * as Debug from 'basegl/debug/GLInspector'
import * as Property    from 'basegl/object/Property'
import {define, mixin, configure, configureLazy, params, lazy, configure2, Composition} from 'basegl/object/Property'

import {EventDispatcher} from 'basegl/event/EventDispatcher'


unsafeWithReparented = (a, newParent, f) ->
  oldParent = a._parent
  a._parent = newParent
  out = f()
  a._parent = oldParent
  out


export class ComponentTargetPath
  constructor: (@componentFamilyID=0, @componentID=0, @shapeID=0) ->
  compare: (t) -> (@compareComponent t) && (@shapeID == t.shapeID)
  compareComponent: (t) -> (@componentFamilyID == t.componentFamilyID) && (@componentID == t.componentID)

export class ComponentTarget
  constructor: (@path=new ComponentTargetPath, @component=null, @shapeDef=null, @element=null) ->

  runInContext: (f) ->
    if @shapeDef? then unsafeWithReparented @shapeDef, @component, f
    else f()

  dispatchEvent: (e) ->
    setObjectProperty e, 'component', @component
    setObjectProperty e, 'shapeDef' , @shapeDef
    @runInContext => @element.dispatchEvent e

  discoverPointerEventTarget: () ->
    pointerEventTargetDiscovery = () ->
      enabled = true
      test = (a) ->
        result = null
        switch a.style.pointerEvents
          when POINTER_EVENTS.INHERIT  then result = enabled
          when POINTER_EVENTS.ENABLED  then result = true
          when POINTER_EVENTS.DISABLED then result = false
        switch a.style.childrenPointerEvents
          when POINTER_EVENTS.INHERIT  then enabled = result
          when POINTER_EVENTS.ENABLED  then enabled = true
          when POINTER_EVENTS.DISABLED then enabled = false
        result
      test
    @runInContext => @element.captureBy(pointerEventTargetDiscovery())


export class MaterialStore
  constructor: () ->
    @materials = new Set
    @uniforms  = new Proxy {},
      set: (target, name, val) =>
        @setUniform name, val
        true

  add: (m) -> @materials.add m

  setUniform: (name, val) ->
    @materials.forEach (mat) ->
      mat.uniforms[name].value = val






export class OffscreenScene extends Composition
  @mixin eventDispatcher: EventDispatcher

  @parameters
    _model      : lazy => new SceneModel
    _camera     : lazy => new Camera
    _width      : 256
    _height     : 256
    _autoUpdate : true

  @properties
    _canvas : null
    _stats  : null


  init: (cfg) ->
    @mixins.eventDispatcher.constructor()
    opts = configure {}, cfg,
      start: true

    @_initRenderer()
    @viewTrough @camera
    world.registerOffscreenScene @
    # if opts.start then animationManager.addEveryDrawAnimation @onEveryFrame

  _initRenderer: () ->
    @_canvas = document.createElementNS 'http://www.w3.org/1999/xhtml', 'canvas'
    @canvas.width  = @width
    @canvas.height = @height
    @canvas.style.display = 'block'
    @_stats    = new Stats
    @_renderer = new THREE.WebGLRenderer {antialias: true, alpha:true, canvas:@canvas}
    @_renderer.setPixelRatio window.devicePixelRatio
    @_renderer.autoClear = false

  ### API ###

  viewTrough: (camera) ->
    @_camera = camera
    @_glCamera = new GLCamera camera, @

  visibleSpace:  () -> [@visibleWidth(), @visibleHeight()]
  visibleWidth:  () -> @width  * @camera.position.z
  visibleHeight: () -> @height * @camera.position.z

  update: () -> @_stats.measure () =>
    @_model.materials.uniforms.zoom = @camera.position.z
    @_model.materials.uniforms.drawBuffer = DRAW_BUFFER.NORMAL
    @_renderer.clear()
    @_renderer.render @_model._glScene, @_glCamera
    @_glCamera.update()

  add: (comp) ->
    def = @model.registerComponent comp
    def.newInstance()

  onEveryFrame: () => @update()



export class Scene extends Composition
  @mixin offscreen: OffscreenScene

  @parameters
    _domElement : null


  ### Initialization ###

  init: (cfg) ->
    @mixins.offscreen.constructor(cfg)

    @_initDOM()
    @_initMouseSupport()
    @_initDebug()
    @updateSize()
    @_idScreenshotRequests = []

    if @autoUpdate
      animationManager.addEveryDrawAnimation @onEveryFrame.bind(@)
    world.registerScene @

  _initDOM: () ->
    domID = @domElement
    if typeof @domElement == 'string' then @_domElement = document.getElementById domID
    if not @domElement instanceof HTMLElement
      raise {"Provided `domElement` is neither a valid DOM ID nor DOM element.", domID}
    @domElement.appendChild @canvas
    @domElement.appendChild @stats.domElement

  _initMouseSupport: () ->
    @_mouseIDBuffer      = new Float32Array 4
    @_lastTarget         = new ComponentTarget
    @_lastTarget.element = @
    @screenMouse         = new THREE.Vector2
    @mouse               = new THREE.Vector2
    @_mouseBaseEvent     = null
    @domElement.addEventListener 'mousedown', (e) => @_lastTarget.dispatchEvent e
    @domElement.addEventListener 'mouseup'  , (e) => @_lastTarget.dispatchEvent e
    @domElement.addEventListener 'click'    , (e) => @_lastTarget.dispatchEvent e
    @domElement.addEventListener 'dblclick' , (e) => @_lastTarget.dispatchEvent e
    @domElement.addEventListener 'mousemove', (e) =>
      @screenMouse.x = e.clientX
      @screenMouse.y = e.clientY
      @mouse.x = (@screenMouse.x-@width/2 ) * @_camera.position.z + @_camera.position.x
      @mouse.y = (@screenMouse.y-@height/2) * @_camera.position.z - @_camera.position.y
      @_mouseBaseEvent = e

  _initIDRecognition: () ->
    @_idTarget = new THREE.WebGLRenderTarget @width, @height, {type: THREE.FloatType, minFilter: THREE.NearestFilter, magFilter: THREE.NearestFilter, format: THREE.RGBAFormat}
    @_idBuffer = new Float32Array (4*@width*@height)

  _initDebug: () ->
    console.log @
    @addEventListener 'keydown', (event) =>
      trigger = event.altKey && event.ctrlKey
      if not trigger then return
      if (event.key >= '0') && (event.key <= '9')
        @_model.materials.uniforms.displayMode = parseInt(event.key)
      else if (event.key == '`')
        Debug.getInspector().toggle()


  ### API ###

  updateSize: () ->
    dwidth  = @domElement.clientWidth
    dheight = @domElement.clientHeight
    if dwidth != @width || dheight != @height
      @_width  = @domElement.clientWidth
      @_height = @domElement.clientHeight
      @offscreen._renderer.setSize @width, @height
      @offscreen._glCamera.onSceneSizeChange()
      @_initIDRecognition()

  onEveryFrame: () => @update()

  update: () -> @_stats.measure () =>
    @updateSize()
    @offscreen.update()

    @model.materials.uniforms.drawBuffer = DRAW_BUFFER.ID
    @offscreen._renderer.render @model._glScene, @offscreen._glCamera, @_idTarget, true
    @offscreen._renderer.readRenderTargetPixels @_idTarget, @screenMouse.x, @_idTarget.height - @screenMouse.y, 1, 1, @_mouseIDBuffer
    if @_idScreenshotRequests.length > 0
      @offscreen._renderer.readRenderTargetPixels @_idTarget, 0,0,@width,@height, @_idBuffer
      for request in @_idScreenshotRequests
        request @_idBuffer
      @_idScreenshotRequests = []

    componentFamilyID = @_mouseIDBuffer[0]
    componentID       = @_mouseIDBuffer[1]
    shapeID           = @_mouseIDBuffer[2]

    ## Finding current ComponentTarget
    targetPath = new ComponentTargetPath componentFamilyID, componentID, shapeID
    if not (@_lastTarget.path.compare targetPath)
      target = null
      if (shapeID == 0)
        target = new ComponentTarget targetPath
        target.element = @
      else
        family         = @_model.lookupComponentFamily componentFamilyID
        if not family then return # when resizing screen sometimes sampled pixels have wrong value!
        component      = family.lookupComponent componentID
        shapeDef       = family.definition.shape
        shapeDefTarget = component.lookupShapeDef shapeID
        target         = new ComponentTarget targetPath, component, shapeDef, shapeDefTarget
        target.element = target.discoverPointerEventTarget()

      ## Dispatching events
      targetChanged    = target.element != @_lastTarget.element
      componentChanged = (not (target.path.compareComponent @_lastTarget.path)) && (target.element.type == Shape)
      if targetChanged || componentChanged
        overEvent  = new MouseEvent 'mouseover' , @_mouseBaseEvent
        outEvent   = new MouseEvent 'mouseout'  , @_mouseBaseEvent
        enterEvent = disableBubbling (new MouseEvent 'mouseenter', @_mouseBaseEvent)
        leaveEvent = disableBubbling (new MouseEvent 'mouseleave', @_mouseBaseEvent)
        @_lastTarget.dispatchEvent outEvent
        @_lastTarget.dispatchEvent leaveEvent
        target.dispatchEvent overEvent
        target.dispatchEvent enterEvent
        @_lastTarget = target


  requestIDScreenshot: (callback) ->
    @_idScreenshotRequests.push callback





export scene = (cfg) ->
  if (typeof cfg) == 'string' then cfg = {domElement: cfg}
  if cfg?.domElement? then new Scene cfg else new OffscreenScene cfg



export class SceneModel extends DisplayObject
  constructor: () ->
    super()
    @_glScene               = new THREE.Scene
    @materials              = new MaterialStore
    @_componentFamilyDefMap = new Map
    @_componentFamilyIDMap  = new Map
    @variables              = @materials.uniforms
    @_componentFamilyIDPool = new IdxPool 1

  registerComponent: (comp) ->
    family = @_componentFamilyDefMap.get comp
    if not family?
      id       = @_componentFamilyIDPool.reserve()
      geometry = new ComponentGeometry comp._localVariables
      family   = new ComponentFamily id, comp, geometry
      @_componentFamilyDefMap.set comp, family
      @_componentFamilyIDMap.set  id  , family
      @materials.add comp.material
      @_glScene.add  family._mesh
    family

  lookupComponentFamily: (id) -> @_componentFamilyIDMap.get id
