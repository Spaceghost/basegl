require("modulereg").registerModule __filename, (require __filename)


# FIXME: move from define* to define*2
# It is better to set things oncei n prototype then per object(!)
### OBSOLETE START ###
export defineProperty = (obj, prop, a) -> Object.defineProperty obj, prop, a
export defineGetter   = (obj, prop, f) -> defineProperty obj, prop, {get: f, configurable: yes}
export defineSetter   = (obj, prop, f) -> defineProperty obj, prop, {set: f, configurable: yes}
### OBSOLETE END ###

export defineDynamicProperty = (obj, prop, a) -> Object.defineProperty obj, prop, a
export defineDynamicGetter   = (obj, prop, f) -> defineProperty obj, prop, {get: f, configurable: yes}
export defineDynamicSetter   = (obj, prop, f) -> defineProperty obj, prop, {set: f, configurable: yes}

export defineProperty2       = (cls, prop, a) -> Object.defineProperty cls.prototype, prop, a
export defineGetter2         = (cls, prop, f) -> defineProperty2 cls, prop, {get: f, configurable: yes}
export defineSetter2         = (cls, prop, f) -> defineProperty2 cls, prop, {set: f, configurable: yes}

# FIXME: Remove these, its just bad design to add methods to global objects
Function::property = (prop, desc) -> defineProperty2 @, prop, desc
Function::getter   = (prop, f)    -> defineGetter2   @, prop, f
Function::setter   = (prop, f)    -> defineSetter2   @, prop, f


export setObjectProperty = (a, name, value, configurable=true) ->
  Object.defineProperty(a, name , {value:value, configurable: configurable})
  a

export consAlias = (a) -> (args...) -> new a args...


export swizzleFields = (cls, ref, fields) ->
  fieldsAssoc   = []
  fieldsAssoNew = []
  for els in [1..fields.length]
    for n,i in fields
      if els == 1 then fieldsAssoc.push [n,[i]]
      else for [an, ai],ii in fieldsAssoc
        fieldsAssoNew.push [an+n, ai.concat [i]]
    fieldsAssoc   = fieldsAssoc.concat fieldsAssoNew
    fieldsAssoNew = []

  for [name,idxs] from fieldsAssoc
    if idxs.length == 1
      fget = (idxs) -> ()  -> @[ref][idxs[0]]
      fset = (idxs) -> (v) -> @[ref][idxs[0]] = v; @.onChanged?()
    else
      fget = (idxs) -> ()  -> @[ref][idx] for idx from idxs
      fset = (idxs) -> (v) ->
        for idx from idxs
          @[ref][idx] = v[idx]
          @.onChanged?()
    cls.getter name, fget idxs
    cls.setter name, fset idxs

export swizzleFieldsXYZW = (cls, ref) -> swizzleFields cls, ref, ['x', 'y', 'z', 'w']
export swizzleFieldsRGBA = (cls, ref) -> swizzleFields cls, ref, ['r', 'g', 'b', 'a']
export swizzleFieldsSTPQ = (cls, ref) -> swizzleFields cls, ref, ['s', 't', 'p', 'q']

export addIndexFields = (cls, ref, num) ->
  fget = (i) -> ()  -> @[ref][i]
  fset = (i) -> (v) -> @[ref][i] = v; @[ref].onChanged?()
  for i in [0..num-1]
    cls.getter i, fget i
    cls.setter i, fset i

export addIndexFieldsStd = (cls, ref) -> addIndexFields cls, ref, 16



export merge = (a,b) ->
  out = {}
  for k,v of a
    out[k] = v
  for k,v of b
    out[k] = v
  out

export mergeMut = (a,b) ->
  for k,v of b
    a[k] = v




################
### Deriving ###
################
# Example:
#   class Bar
#     test1: 5
#     test2: 7
#
#   class Foo
#     mixin @, bar: Bar
#
#     constructor: () ->
#       @mixins.bar.constructor()

isMagicName = (s) => s.startsWith('_') && s.endsWith('_')

export mixinBy = (f) => (cls, targets) =>
  if not cls::_mixins?
    cls::_mixins = {}
    defineGetter2 cls, 'mixins', ->
      objMixins = {}
      for name, s of @_mixins
        objMixins[name] =
          type:        s.type
          constructor: s.constructor.bind @
      @_mixins = objMixins
      objMixins

  parentNames = new Set Object.getOwnPropertyNames(cls.prototype)
  for child, childCls of targets
    cls::_mixins[child] =
      type: childCls
      constructor: (args...) -> @[child] = new childCls args...
    for name in Object.getOwnPropertyNames(childCls.prototype)
      if not (parentNames.has name) && name != 'constructor' && not isMagicName(name) && name != 'init' && f name
        mixinSingle cls, childCls, child, name

export mixinByRegExp = (reg) ->
  src   = reg.source
  flags = reg.flags
  nreg  = new RegExp "^#{src}$", flags
  mixinBy (a) => a.match(nreg)

export mixinSingle = (cls, childCls, child, name) ->
  defineSetter2 cls, name, (v) -> @[child][name] = v
  defineGetter2 cls, name,     ->
    target = @[child]
    out    = target[name]
    if out instanceof Function then out = out.bind target
    out

export mixinAll     = mixinBy     => true
export mixinPrivate = mixinBy (a) =>     a.startsWith('_')
export mixinPublic  = mixinBy (a) => not a.startsWith('_')
export mixin        = mixinAll

Function::mixin        = (args...) -> mixin        @, args...
Function::mixinAll     = (args...) -> mixinAll     @, args...
Function::mixinPrivate = (args...) -> mixinPrivate @, args...
Function::mixinPublic  = (args...) -> mixinPublic  @, args...


# class Bar
#   # test1: 5
#   # test2: 7
#
# class Foo
#   @mixin bar: Bar
#
#   constructor: () ->
#     console.log @mixins
#     @mixins.bar.constructor()
#
# foo = new Foo
# console.log foo



############################
### Object configuration ###
############################

defineWith = (f) => (obj, cfg) =>
  for n,v of cfg
    n2 = n
    if n.startsWith '__'
      n  = n.slice(1)
      n2 = n.slice(1)
    else if n.startsWith '_'
      n2 = n.slice(1)
      defineGetter obj, n2, ((n) => => obj[n])(n)
    obj[n] = f v, n2
  obj

configureUsing = (f) => (obj, cfg, cfgDef) =>
  def = defineWith (v,n2) =>
    v2 = cfg?[n2]
    if v2 != undefined then v2 else f v, obj
  def obj, cfgDef


defineWith2 = (f) => (cls, cfg) =>
  for n,v of cfg
    n2 = n
    if n.startsWith '__'
      n  = n.slice(1)
      n2 = n.slice(1)
    else if n.startsWith '_'
      n2 = n.slice(1)
      defineGetter2 cls, n2, ((n) => -> @[n])(n)
    cls::[n] = f v, n2
  cls


# Defines a property and according getters. See `configure` for more details
export define = defineWith (a) => a
export define2 = defineWith2 (a) => a



class Lazy
  constructor: (@delayed) ->

export lazy = consAlias Lazy

export params = (cls, cfg) ->
  if not cls::_params_? then cls::_params_ = {}
  cparams = cls::_params_
  for name,val of cfg
    cparams[name] = val
  define2 cls, cfg



Function::parameters = (args...) -> params @, args...
Function::properties = (args...) -> define2 @, args...

# Configures given object using the user configuration `cfg`, according to default configuration `cfgDef`.
# It iterates over default configuration and if the appropriate value in user configuration is not `undefined`
# it is used instead of default one.
#
# The naming of keys in default configuration sets their security level:
#   <name>   - ordinary names are converted to public fields
#   _<name>  - names starting with single underscore are converted to private fields with getter
#   __<name> - names starting with double underscore are converted to private fields (with single underscore) without getter
#
# The user configuration should not use names with underscore, for example
#
#   class Foo
#     constructor: (cfg) ->
#       configure @, cfg,
#         test1   : 1
#         _test2  : 2
#         __test3 : 3
#   foo = new Foo
#     test3: 10
#
#   >> Foo {test1: 1, _test2: 2, _test3: 10}
#
export configure = configureUsing (a) => a


# Configures given object using the provided configuration. See `configure` for more details.
# This version assumes the default configuration values are lambdas in order not to construct
# heavyweight default values when not necessary.
export configureLazy = configureUsing (f,obj) => f obj



export configure2 = configureUsing (a) =>
  if a instanceof Lazy then a.delayed() else a


configureParameters = (self, cfg) ->
  configure2 self, cfg, self._params_

export class Composition
  constructor: (cfg,args...) ->
    configureParameters @, cfg
    @init?(cfg,args...)


# class C1 extends Composition
#   # @parameters
#   #   p1   : 1
#   #   _p2  : 2
#   #   __p3 : 3
#   test1: () ->
#     console.log 'C1.test1', @, @p1, @_p2, @_p3
#
# class C2 extends Composition
#   @mixin c1:C1
#
#   # test1: () ->
#   #   console.log 'C2.test1'
#   #   @c1.test1()
#
#   init: () ->
#     @mixins.c1.constructor.call @
#
#
# console.log '-------'
#
# c2 = new C2
# c2_2 = new C2
# # c2.test1()
# # c2_2.test1()
#
# console.log c2
# console.log c2_2
#
# console.log c2.test1
# console.log c2_2.test1
#
# raise "end"
