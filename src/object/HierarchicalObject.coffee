import {Composable} from "basegl/object/Property"


##########################
### HierarchicalObject ###
##########################

export class HierarchicalObject extends Composable
  init: () ->
    @_children = new Set
    @_parent   = null

  @property 'parent', get: -> @_parent

  @getter 'children', -> @_children

  addChild: (a) ->
    @_children.add(a)
    a._parent = @
    @

  addChildren: (children...) ->
    for child from children
      @addChild child

  getParentChain: () ->
    lst = if @_parent? then @_parent.getParentChain() else []
    lst.push @
    lst
