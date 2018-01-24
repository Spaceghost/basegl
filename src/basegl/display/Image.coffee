require("modulereg").registerModule __filename, (require __filename)

import * as THREE   from 'three'
import * as Reflect from 'basegl/object/Reflect'


export DataTexture   = THREE.DataTexture
export CanvasTexture = THREE.CanvasTexture
Reflect.addTypeInformation DataTexture
Reflect.addTypeInformation CanvasTexture
