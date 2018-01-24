require("modulereg").registerModule __filename, (require __filename)

import * as OpenType from 'opentype.js'


import * as paper from 'paper'
import {localExpr}        from 'basegl/math/Common'
import {circle, glslShape, union, grow, negate, rect, quadraticCurve, path}      from 'basegl/display/Shape'
import {vector, point}       from 'basegl/math/Vector'
import * as Color     from 'basegl/display/Color'
import * as Image     from 'basegl/display/Image'
M = require 'basegl/math/Common'


INF = 1e20


# paper.setup()
# path = new paper.Path()
# start = new paper.Point(100, 100)
# path.moveTo(start)
# path.lineTo(start.add([ 200, -50 ]))
#
# console.log path


export textureSizeFor  = (i) -> closestPowerOf2 (Math.ceil (Math.sqrt i))
export closestPowerOf2 = (i) -> Math.pow(2, Math.ceil(Math.log2 i))

export encodeArrayInTexture = (arr) ->
  len  = arr.length
  els  = Math.ceil (len/4)
  size = textureSizeFor els
  size = 256
  tarr = new Float32Array (size*size*4)
  tex  = new Image.DataTexture tarr, size, size, THREE.RGBAFormat, THREE.FloatType
  tex.needsUpdate = true
  for idx in [0...len]
    tarr[idx] = arr[idx]
  console.log 'SIZE:', size
  tex



PATH_COMMAND =
  Z: 0 # end of letter
  M: 1
  L: 2
  Q: 3

encodePath    = (commands) -> encodePathMut commands, []
encodePathMut = (commands, path) ->
  console.log commands
  for command in commands
    switch command.type
      when 'M' then path.push PATH_COMMAND.M, command.x, command.y
      when 'L' then path.push PATH_COMMAND.L, command.x, command.y
      when 'Q' then path.push PATH_COMMAND.Q, command.x1, command.y1, command.x, command.y
      # when 'Z' then path.push PATH_COMMAND.Z
  path

generatePathsTexture = (paths) ->
  defs = (encodePath p.commands for p in paths)
  cmds = []
  for def in defs
    for cmd in def
      cmds.push cmd
  for i in [0..20]
    console.log cmds[i]
  encodeArrayInTexture cmds







letterShapeDef = eval localExpr (commands) ->
  sections = []
  paths    = []
  origin   = point 0,0
  offset   = point 0,0
  # console.log commands
  done = false
  skip = false


  for command in commands
    if done then break
    switch command.type
      when 'L'
        dest = point (command.x - origin.x), (command.y - origin.y)
        sections.push (quadraticCurve(dest,dest))
        offset   = point 0,0

      when 'Q'
        ctrl = point (command.x1 - origin.x), (command.y1 - origin.y)
        dest = point (command.x  - origin.x), (command.y  - origin.y)
        sections.push (quadraticCurve(ctrl,dest))
        offset   = point 0,0

      when 'Z'
        x = 1
        skip = true
        # origin = point 0,0
      when 'M'
        # console.log '>>', origin.x, origin.y
        offset = point command.x, command.y
        nnx = command.x
        nny = command.y
        # console.log nnx, nny
        # console.log origin.x, origin.y
        origin.x = nnx
        origin.y = nny
        # console.log '<<', origin.x, origin.y
        # origin.x = 0
        # origin.y = 0
        skip = true
      #   paths.push path(sections)
      #   sections = []
    if not skip
      origin.x = command.x
      origin.y = command.y
    skip = false
  paths.push path(sections)

  s = paths[0]
  for p in paths.slice(1)
    s = s + p
  s.fill(Color.rgb [1,1,1]).move(64,64)

  # s = path [ quadraticCurve(point(50,20), (point 100, 0))
  #          , quadraticCurve(point(-50,50), (point 0, 100))
  #          , quadraticCurve(point(-50,20) , (point -100,-100))
  #          ]
  # s.fill(Color.rgb [1,1,1])


# letterShape = letterShapeDef([1,2,3])


# letterShapeDef = eval localExpr () ->
#   s = path [ quadraticCurve(point(50,20), (point 100, 0))
#            , quadraticCurve(point(-50,50), (point 0, 100))
#            , quadraticCurve(point(-50,20) , (point -100,-100))
#            ]
#
# letterShape = letterShapeDef()

export letterShape =  null

addSVGHeader = (width, height, s) -> """
<svg version="1.1"
     baseProfile="full"
     xmlns="http://www.w3.org/2000/svg"
     height="#{width}"
     width="#{height}">

  <g fill="red" stroke="white" stroke-width="3"> #{s} </g>
</svg>
"""

svgex = '''
<svg version="1.1"
     baseProfile="full"
     xmlns="http://www.w3.org/2000/svg"
     height="100"
     width="100">
  <g fill="red" stroke="white" stroke-width="3"> <circle cx="50" cy="50" r="40"/> </g>
</svg>'''





export genVectorDefinitionTexture = (f) ->
  OpenType.load 'fonts/DejaVuSansMono.ttf', (err, font) ->
    if (err) then f null, err
    else
      fontSize = 128
      pathx   = font.getPath '@', 0, 0, fontSize
      console.log 'PATH', pathx
      console.log font
      texture = generatePathsTexture [pathx]
      f texture, null
      #
      # size = 16
      # dataColor = new Float32Array( size * size * 4 );
      # for i in [0...size]
      #     dataColor[ i * 3 ]     = 1;
      #     dataColor[ i * 3 + 1 ] = 1;
      #     dataColor[ i * 3 + 2 ] = 1;
      #     dataColor[ i * 3 + 3 ] = 1;
      # map = new THREE.DataTexture(dataColor, size, size, THREE.RGBAFormat, THREE.FloatType )
      # map.needsUpdate = true

      # f map, null

export testGenerate = (f) ->
  OpenType.load 'fonts/DejaVuSansMono.ttf', (err, font) ->
    if (err) then alert('Font could not be loaded: ' + err)
    else
      size = 256
      fontSize = 128
      pathx = font.getPath 'c', 0, 0, fontSize
      console.log pathx
      letterShape = letterShapeDef pathx.commands
      f(letterShape)
      svg = pathx.toSVG()
      console.log svg
    # window.pathx = pathx
    # svg = addSVGHeader fontSize, fontSize, svg
    # console.log svg
    #
    # canvas        = document.createElement('canvas');
    # canvas.width  = size
    # canvas.height = size
    # canvas.style.position = 'absolute'
    # document.body.appendChild canvas
    #
    # ctx = canvas.getContext '2d'
    #
    # # paper.setup(canvas)
    # paper.setup()
    # path = new paper.Path
    # path.strokeColor = 'black'
    # start = new paper.Point(0,0)
    # path.moveTo(start)
    # path.lineTo(start.add([ 200, 200 ]))
    #
    # glyph = paper.project.importSVG svg
    # console.log '!!', glyph
    # glyph2 = glyph.children[0].children[0]
    # glyph2.position.y += 128
    # glyph2.position.x += 32





    # ccc = new paper.Path.Circle
    #   center: paper.view.center
    #   radius: 3
    #   fillColor: 'red'
    #
    # # window.addEventListener 'mousemove', (e) ->
    # #   mp = new paper.Point e.clientX, e.clientY
    # #   nearestPoint = glyph2.getNearestPoint mp
    # #   ccc.position = nearestPoint
    # #   console.log glyph2.contains mp
    #
    # console.log 'start'
    #
    # distField = new Uint8ClampedArray (size * size)
    #
    # # for x in [0...size]
    # #   for y in [0...size]
    # #     pt = new paper.Point x,y
    # #     nearestPoint = glyph2.getNearestPoint pt
    # #     # v  = nearestPoint.subtract pt
    # #     # len = Math.round(v.length)
    # #     # distField[y*size + x] = len
    # #     # console.log len
    # #     # ctx.fillStyle = 'rgba(' + x + ',' + y + ',' + 255 + ',' + 1 + ')'
    # #     # ctx.fillStyle = 'rgba(' + len + ',' + len + ',' + len + ',' + 1 + ')'
    # #     # ctx.fillRect x, y, 1, 1
    # # console.log 'end'
    #
    # preview = new Uint8ClampedArray (size * size * 4)
    # for i in [0...size * size]
    #   preview[i*4 + 3] = distField[i]
    #
    #
    # idata = new ImageData(preview,size,size)
    # ctx.putImageData idata, 0, 0
    #
    # window.paper = paper
    #
    #
    #
    # # console.log glyph
    # # for i in [0..256]
    # #   for j in [0..256]
    # #     console.log glyph.contains(new paper.Point i,j)
    # # path.draw(ctx);





export class Generator
  constructor: (@fontSize=24, @buffer=3, @radius=8, @cutoff=0.25, @fontFamily='sans-serif', @fontWeight='normal')  ->
    @size = @fontSize + @buffer * 2

    @canvas        = document.createElement('canvas');
    @canvas.width  = @size
    @canvas.height = @size

    console.log 'CANVAS SIZE:', @size

    # document.body.appendChild @canvas
    @canvas.style.position = 'absolute'
    @canvas.style.y = 1000

    @ctx = @canvas.getContext('2d')
    @ctx.font = @fontWeight + ' ' + @fontSize + 'px ' + @fontFamily
    @ctx.textBaseline = 'middle'
    @ctx.fillStyle    = 'black'

    @gridOuter = new Float64Array (@size * @size)
    @gridInner = new Float64Array (@size * @size)
    @f         = new Float64Array (@size)
    @d         = new Float64Array (@size)
    @z         = new Float64Array (@size + 1)
    @v         = new Int16Array   (@size)

    # hack around https://bugzilla.mozilla.org/show_bug.cgi?id=737852
    @middle = Math.round((@size/2) * (if navigator.userAgent.indexOf('Gecko/') >= 0 then 1.2 else 1))


  draw: (char) ->
    @ctx.clearRect 0, 0, @size, @size
    @ctx.fillText char, @buffer, @middle

    imgData      = @ctx.getImageData 0, 0, @size, @size
    alphaChannel = new Uint8ClampedArray @size * @size

    for i in [0...@size * @size]
        a = imgData.data[i * 4 + 3] / 255 # alpha value
        @gridOuter[i] = if a == 1 then 0   else (if a == 0 then INF else Math.pow(Math.max(0, 0.5 - a), 2))
        @gridInner[i] = if a == 1 then INF else (if a == 0 then 0   else Math.pow(Math.max(0, a - 0.5), 2))

    edt @gridOuter, @size, @size, @f, @d, @v, @z
    edt @gridInner, @size, @size, @f, @d, @v, @z

    for i in [0...@size * @size]
        d = @gridOuter[i] - @gridInner[i]
        alphaChannel[i] = Math.max(0, Math.min(255, Math.round(255 - 255 * (d / @radius + @cutoff))))


    preview = new Uint8ClampedArray (@size * @size * 4)
    for i in [0...@size * @size]
      preview[i*4 + 3] = alphaChannel[i]



    idata = new ImageData(preview,@size, @size)
    @ctx.putImageData idata, 0, 0


    # alphaChannel
    @canvas


# 2D Euclidean distance transform by Felzenszwalb & Huttenlocher https://cs.brown.edu/~pff/papers/dt-final.pdf
edt = (data, width, height, f, d, v, z) ->
  for x in [0...width]
    for y in [0...height]
      f[y] = data[y * width + x]
    edt1d(f, d, v, z, height)
    for y in [0...height]
      data[y * width + x] = d[y]

  for y in [0...height]
    for x in [0...width]
      f[x] = data[y * width + x]
    edt1d(f, d, v, z, width)
    for x in [0...width]
      data[y * width + x] = Math.sqrt(d[x])


# 1D squared distance transform
edt1d = (f, d, v, z, n) ->
    v[0] = 0
    z[0] = -INF
    z[1] = +INF

    k = 0
    for q in [1...n]
      s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
      while (s <= z[k])
        k--
        s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
      k++
      v[k] = q
      z[k] = s
      z[k + 1] = +INF

    k = 0
    for q in [0...n]
      while (z[k + 1] < q)
        k++
      d[q] = (q - v[k]) * (q - v[k]) + f[v[k]]
