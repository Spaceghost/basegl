require("modulereg").registerModule __filename, (require __filename)

import * as Property from "basegl/object/Property"


##########################
### HierarchicalObject ###
##########################

export class HierarchicalObject
  constructor: (children=[]) ->
    @_children = new Set()
    @_parent   = null
    @addChildren children...

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
