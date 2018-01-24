
import * as acorn from "acorn"
import * as walk  from "acorn/dist/walk"
import * as escodegen from "escodegen"


memberExpression = (parser, base, prop) ->
  node          = new acorn.Node parser
  node.type     = 'MemberExpression'
  node.object   = base
  node.property = prop
  node

identifier = (parser, name) ->
  node      = new acorn.Node parser
  node.type = 'Identifier'
  node.name = name
  node

callExpression = (parser, callee, args) ->
  node           = new acorn.Node parser
  node.type      = 'CallExpression'
  node.callee    = callee
  node.arguments = args
  node

expressionStatement = (parser, expression) ->
  node            = new acorn.Node parser
  node.type       = 'ExpressionStatement'
  node.expression = expression

arrowFunctionExpression = (parser, params, body) ->
  node            = new acorn.Node parser
  node.type       = 'ArrowFunctionExpression'
  node.params     = params
  node.body       = body
  node.expression = false
  node.generator  = false
  node

blockStatement = (parser, body) ->
  node      = new acorn.Node parser
  node.type = 'BlockStatement'
  node.body = body
  node

returnStatement = (parser, argument) ->
  node          = new acorn.Node parser
  node.type     = 'ReturnStatement'
  node.argument = argument
  node


replace = (parent, oldVal, newVal) ->
  for k,v of parent
    if (v == oldVal)
      parent[k] = newVal
      return
    else if v instanceof Array
      for el,i in v
        if el == oldVal
          v[i] = newVal
          return
  console.log "OH NO"


export overloadCode = (map, f) ->
  codeStr = f.toString()
  code    = codeStr.replace 'function (', 'function _ ('
  parser  = new acorn.Parser {}, code
  ast     = parser.parse()
  args    = (p.name for p in ast.body[0].params)

  ### Operator overloading ###
  operatorMap = map.operator
  if operatorMap
    walk.ancestor ast,
      BinaryExpression: (node, ancestors) ->
        parent = ancestors[ancestors.length - 2]
        name   = operatorMap[node.operator]
        if name
          prop = identifier parser, name
          call = callExpression parser, prop, [node.left, node.right]
          replace parent, node, call


  ### Monadic overloading ###
  bindOverload = map.bind
  blockTransform = (node) ->
    if node.body.length > 1
      head     = node.body[0]
      rest     = node.body.slice(1)
      # if head.type == 'VariableDeclaration'
      arg      = head.declarations[0].id # FIXME
      bind     = identifier parser, bindOverload
      subBlock = blockStatement parser, rest
      arrow    = arrowFunctionExpression parser, [arg], subBlock
      line     = returnStatement parser, (expressionStatement parser, (callExpression parser, bind, [arg, arrow]))
      node.body = [head, line]
      blockTransform subBlock
      # else

  if bindOverload
    walk.ancestor ast,
      BlockStatement: (node, ancestors) ->
        parent = ancestors[ancestors.length - 2]
        if parent.type == 'FunctionDeclaration'
          blockTransform node


  newCode = '(' + escodegen.generate(ast) + ')'
  if bindOverload then newCode = 'bind => ' + newCode
  newCode

export overload = (map, f) ->
  eval (overloadCode map, f)

export binaryOperatorMap =
  operator:
    '=='  : 'M.eq'
    '===' : 'M.eq'
    '!='  : 'M.neq'
    '!==' : 'M.neq'
    '<'   : 'M.lt'
    '<='  : 'M.lte'
    '>'   : 'M.gt'
    '>='  : 'M.gte'
    '<<'  : 'M.lshift'
    '>>'  : 'M.rshift'
    '>>>' : 'M.rshift2'
    '+'   : 'M.add'
    '-'   : 'M.sub'
    '*'   : 'M.mul'
    '/'   : 'M.div'
    '%'   : 'M.mod'
    '||'  : 'M.or'
    '&&'  : 'M.and'




###################################################
### PLAYGROUND ###
###################################################


class Monadic
  constructor: (@fromMonadic) ->
  fromMonadic: -> @fromMonadic


class Monad
  constructor: () ->

  toMonadic: () ->
    self = @
    new Monadic (stack) ->
      out = self
      if stack
        out = stack[0].create out, stack.slice(1)
      out


bind = (a, f) ->
  if a instanceof Monadic
    new Monadic (stack) ->
      out = a.fromMonadic(stack).bind f, stack
      if out instanceof Monadic then out = out.fromMonadic(stack)
      if not (out instanceof Monad)
        if stack
          out = stack[0].liftx out, stack.slice(1)
      out
  else
    f a


### Maybe ###

class Maybe extends Monad
  bind: (f) -> if @ instanceof Just then f @val else nothing
  @lift: (a) -> just a

class Nothing extends Maybe
class Just    extends Maybe
  constructor: (@val) -> super()

just    = (a) -> new Just a
nothing = new Nothing


### Either ###

class Either extends Monad
  bind: (f) -> if @ instanceof Right then f @val else @
  @create: (a) -> right a

class Left  extends Either
  constructor: (@val) -> super()

class Right extends Either
  constructor: (@val) -> super()

right = (a) -> new Right a
left  = (a) -> new Left  a


### MaybeT ###

class MaybeT extends Monad
  constructor: (@val) -> super()
  @create: (a, stack) ->
    out = just a
    if stack
      out = stack[0].create out, stack.slice(1)
    new MaybeT out

  bind: (f, stack) -> new MaybeT (bind @val, (v) ->
      if v instanceof Nothing then console.log "TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      else
        out = f (v.val)
        if out instanceof Monadic then out = out.fromMonadic(stack)
        console.log ">>>", out
        out = out.val
        out
  )

bindnull = (a, f) -> if a == null then null else f a

maybeTest = new Just 5
# console.log (maybeTest instanceof Just)

monadTestCode = '''
function () {
  let b = right(1).toMonadic();
  let a = right(2).toMonadic();
  return 8 + b;

}
'''



overloadMap2 =
  bind: 'bind'

foo = overload overloadMap2, monadTestCode
