path = require('path')

window.__shared__ = {}
shared = window.__shared__
shared.modules = {}

export registerModule = (modulePath, module) ->
    sections = modulePath.split(/[\/\\]+/)
    fileName = sections.slice(-1)[0]
    sections = sections.slice 0, -1
    baseName = path.basename fileName, path.extname fileName

    ptr = shared.modules
    for section from sections
      nptr = ptr[section]
      if not nptr
        nptr = {}
        ptr[section] = nptr
      ptr = nptr

    ptr[baseName] = module
