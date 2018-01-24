require("modulereg").registerModule __filename, (require __filename)


###############
### BinPack ###
###############
# http://blackpawn.com/texts/lightmaps/default.html

export class BinPack
  constructor: (w,h) ->
    @root = new Node (new Rect 0,0,w,h)

  insert: (w,h) ->
    rect = new Rect 0,0,w,h
    node = @root.insert rect
    if node? then node.rect else null


export class Rect
  constructor: (@x, @y, @w, @h) ->
  fitsIn:      (outer) -> (outer.w >= @w) && (outer.h >= @h)
  sameSizeAs:  (other) -> (@w == other.w) && (@h == other.h)


export class Node
  constructor: (@rect=null, @left=null, @right=null, @filled=false) ->
  insert: (rect) ->
    if @left != null          then return @left.insert(rect) || @right.insert(rect)
    if @filled                then return null
    if not rect.fitsIn(@rect) then return null
    if rect.sameSizeAs(@rect) then @filled = true; return @
    @left      = new Node
    @right     = new Node
    widthDiff  = @rect.w - rect.w
    heightDiff = @rect.h - rect.h
    me         = @rect
    if widthDiff > heightDiff
        @left.rect  = new Rect me.x          , me.y , rect.w        , me.h
        @right.rect = new Rect me.x + rect.w , me.y , me.w - rect.w , me.h
    else
        @left.rect  = new Rect me.x , me.y          , me.w , rect.h
        @right.rect = new Rect me.x , me.y + rect.h , me.w , me.h - rect.h
    return @left.insert rect
