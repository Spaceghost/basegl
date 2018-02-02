import {eventDispatcherMixin} from "basegl/event/EventDispatcher"
import {Vector}               from "basegl/math/Vector"
import {mat4}                 from 'gl-matrix'
import {Composable}           from "basegl/object/Property"


#####################
### DisplayObject ###
#####################

export POINTER_EVENTS =
  INHERIT:  "inherit"
  ENABLED:  "enabled"  # enable  starting with this element
  DISABLED: "disabled" # disable starting with this element

export styleMixin = -> @style = new DisplayStyle
export class DisplayStyle extends Composable
  init: () ->
    @pointerEvents         = POINTER_EVENTS.INHERIT
    @childrenPointerEvents = POINTER_EVENTS.INHERIT

export class DisplayObject extends Composable
  init: () ->
    @mixins [styleMixin, eventDispatcherMixin]
    @origin   = mat4.create()
    @xform    = mat4.create()
    @position = new Vector [0,0,0], @onTransformed.bind @
    @scale    = new Vector [1,1,1], @onTransformed.bind @
    @rotation = new Vector [0,0,0], @onTransformed.bind @

  setOrigin: (newOrigin) ->
    @origin = newOrigin
    @updateChildrenOrigin()

  updateChildrenOrigin: () ->
    @xform = mat4.create()
    mat4.scale     @xform, @xform, @scale.xyz
    mat4.rotateX   @xform, @xform, @rotation.x
    mat4.rotateY   @xform, @xform, @rotation.y
    mat4.rotateZ   @xform, @xform, @rotation.z
    mat4.translate @xform, @xform, @position.xyz
    mat4.multiply(@xform, @origin, @xform)

    @children.forEach (child) =>
      child.setOrigin @xform

  onTransformed: () ->
    @updateChildrenOrigin()


export group = (elems) ->
  g = new DisplayObject()
  for el in elems
    g.addChild el
  g
