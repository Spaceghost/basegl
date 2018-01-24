require("modulereg").registerModule __filename, (require __filename)

import * as Spector from 'spectorjs'
Spector.Spector::toggle = () ->
  @.displayUI()
  # FIXME: This is ugly. If anybody has idea how to discover the spector root div better, please fix it.
  spectorGUIChild = document.getElementsByClassName("captureMenuComponent")[0]
  if spectorGUIChild
    style = spectorGUIChild.parentNode.style
    if style.display == "none" then style.display = ""
    else style.display = "none"


_inspector = null
export getInspector = () ->
  if not _inspector then _inspector = new Spector.Spector()
  _inspector
