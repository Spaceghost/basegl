export {scene}                           from 'basegl/display/Scene'
export {symbol}                          from 'basegl/display/Symbol'
export {text}                            from 'basegl/display/text/Font'
import * as World from 'basegl/display/World'


import * as _Math from 'basegl/math/Common'
export Math = _Math

export expr = (args...) -> throw 'Do not use `basegl.expr` without `basegl-preprocessor`. If you use webpack, you can use `basegl-loader`.'


export world = new World.World
