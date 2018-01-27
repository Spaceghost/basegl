
tcID = 0

getNextID = () ->
  id = tcID
  tcID += 1
  id

tcName = (i) -> '__typeclass__' + i

export define = (name='unnamed') ->
  id   = getNextID()
  prop = tcName id
  func = (obj, args...) ->
    dst = obj[prop]
    if not dst
      throw {msg: "Object does not implement `#{name}` type class.", obj}
    dst.call obj, args...
  func.id = id
  func.tc = name
  func

export implement = (obj, tc, f) ->
  obj.prototype[tcName tc.id] = f
