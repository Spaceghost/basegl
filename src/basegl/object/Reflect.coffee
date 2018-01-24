require("modulereg").registerModule __filename, (require __filename)

import * as TypeClass from 'TypeClass'



export all = (f) => (ns) =>
  result = true
  for n from ns
    if not f(n)
      result = false
      break
  result



##############
### TypeOf ###
##############

### Definition ###
export typeOf = TypeClass.define 'Reflect.typeOf'
export addTypeInformation = (t) => TypeClass.implement t, typeOf, () -> t

### Instances ###
addTypeInformation Array
addTypeInformation Boolean
addTypeInformation Number
addTypeInformation String


### Utils ###
export ofType     = (t, a) => typeOf(a) == t
export isNumber   = (a) => ofType Number, a
export isString   = (a) => ofType String, a
export isArray    = (a) => ofType Array , a


######################
### Type discovery ###
######################

export isNumeric  = (a) -> !isNaN(parseFloat(a)) && isFinite(a)
export isIntegral = (a) -> a % 1 == 0
export areNumbers = all isNumber
