import {HierarchicalObject} from "basegl/object/HierarchicalObject"
import {setObjectProperty}  from "basegl/object/Property"
import {Composable}         from "basegl/object/Property"


#######################
### EventDispatcher ###
#######################

export class EventDispatcher extends Composable
  init: () ->
    @_hierarchy        = @mixin HierarchicalObject
    @_captureListeners = {}
    @_bubbleListeners  = {}

  addEventListener: (name, callback, useCapture=false) ->
    ls = if useCapture then @_captureListeners else @_bubbleListeners
    cs = ls[name] ? new Set()
    cs.add callback
    ls[name] = cs

  removeEventListener: (name, callback, useCapture=false) ->
    ls = if useCapture then @_captureListeners else @_bubbleListeners
    cs = ls[name]
    if cs?
      cs.delete callback
      if cs.size == 0 then delete ls[name]

  dispatchEvent: (e) ->
    chain  = @getParentChain()
    rchain = chain.slice().reverse()
    state  = {stop: false, stopImmediate: false}
    setObjectProperty e, 'target'                   , @
    setObjectProperty e, 'path'                     , rchain
    setObjectProperty e, 'stopPropagation'          , () -> state.stop          = true
    setObjectProperty e, 'stopImmediatePropagation' , () -> state.stopImmediate = true

    dispatchPhase = (chain, phase, pls) ->
      setObjectProperty e, 'eventPhase', phase
      for el in chain
        setObjectProperty e, 'currentTarget', el
        fset = el[pls][e.type]
        if fset? then fset.forEach (f) ->
          f e
          if state.stopImmediate then return (!e.defaultPrevented)
        if state.stop || not e.bubbles then return (!e.defaultPrevented)

    dispatchPhase(chain,  e.CAPTURING_PHASE, '_captureListeners')
    if state.stop || state.stopImmediate then return (!e.defaultPrevented)
    dispatchPhase(rchain, e.BUBBLING_PHASE,  '_bubbleListeners')

  captureBy: (f) ->
    chain  = @getParentChain()
    target = null
    for el in chain
      if f el then target = el
    return target

export eventDispatcherMixin = -> @_eventDispatcher = @mixin EventDispatcher

export disableBubbling = (e) -> setObjectProperty e, 'bubbles', false


# class C2 extends Composable
#   init: () ->
#     @c1      = @mixin C1
#     @c2_p1   = 11
#     @_c2_p2  = 12
#     @_c2_p22 = 16
#     @__c2_p3 = 13
