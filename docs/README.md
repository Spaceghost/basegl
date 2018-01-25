# Setting up

To install `BaseGL` you need to import it to your project. The easiest way to do it would be by invoking `npm install BaseGL`. Let's create our first application!

Let's start with a small boilerplate. Here is our `index.html`:
```html
<!DOCTYPE html>
<html>
	<head>
		<meta charset=utf-8>
		<title>BaseGL Application</title>
		<style>
            html { height: 100%; }
            body { margin:0; display: flex; height: 100%}
		</style>
	</head>
	<body>
	</body>
    <div id="basegl-root"></div>
    <script language="javascript" src="index.js"></script>
</html>
```

... and our `index.coffee` file (it generates the `index.js` file loaded by html):

```coffeescript
import * as basegl from 'basegl'
```

That's all! We are ready to create our first app. The `basegl-root` div will host our WebGL environment and it is styled to always occupy the whole window.


# Scenes

Scene represents a canvas you can draw on. There are two types of scenes, on-screen and off-screen. The former are used to display graphics to the user, the later could be used to prepare cached textures. The font engine, for example, uses off-screen scene to create [font atlas](https://en.wikipedia.org/wiki/Texture_atlas). 

You can create as many scenes as you wish. Each on-screen scene must be provided with a dom-element where it should display it's content. Scenes do not share data. If you create an object and you place it in several scenes, it will be stored several times in memory and will not be shared between GPU calls. If you would like to create multiple divs showing the same scene using different styles or cameras, you should use multiple scene views instead (note: scene views are not yet supported, contact authors if you need them now).

### Creating a scene

In order to create a scene use a `scene` function:

```coffeescript
scene = basegl.scene
  domElement: 'basegl-root'
```

There are multiple options to configure a scene:

| Parameter name    | Default value   | Description  |
| ----------------- |:-------------   | :-----   |
| `domElement`      | `null`          | Dom id or dom reference. If not provided, an off-screen scene is created. |
| `camera`          | `new Camera`    | Camera object the scene would be viewed with. |
| `width`, `height` | `512`           | Scene dimensions. Overriden if used by on-screen scene with `autoUpdate` enabled. |
| `autoUpdate`      | `true`          | If enabled, the scene would be refreshed if something changed. If disabled, you would need to use the `update` method to perform manual updates |

# Shapes

Shapes are BaseGL primitives allowing you to define how objects look like. A shape is constructed from shape primitives. There are dozens of shape primitives (circle, rectangle, line, ...) and shape operations (merge, intersect, polar coordination transformation, ...) built-in BaseGL. You can also define your own, however for vast majority of use cases you would not need to. 

## How shapes are defined
Although BaseGL was designed to abstract WebGL internals and make many optimizations under the hood, it is very important to understand how shapes work in order to create the most performance efficient applications. When used correctly, you can create scenes which display millions of gui elements, 60 frames per second on modern laptop.

Before sending to graphics card, the primitives are converted to [Signed Distance Field functions (SDFs)](https://en.wikipedia.org/wiki/Signed_distance_function). Basically SDF describes how far each particular point in 2D space is from the border of the shape. For example, a SDF equation to define circle is 

```GLSL
float sdf_circle (vec2 p, float radius) {
  return length(p) - radius;
}
```

The equation is very simple - `p` is current point in space (pixel on screen). Shapes are always defined with center in `(0,0)` point. So with given `radius` the distance to border of the circle is length of the point `p` from point `(0,0)` minus the radius.

All built-in SDF shapes and operations are defined [here](https://github.com/wdanilo/basegl/blob/master/src/shader/sdf/sdf.glsl). You can inspect CoffeeScript bindings [here](https://github.com/wdanilo/basegl/blob/master/src/basegl/display/Shape.coffee).

SDFs are very fast to render because the equation can be computed for each pixel on the screen in parallel. However, you should be aware that very complex shapes can drastically slow down your application. If your shape consist of 100 circles, we would need to compute the equation for each circle in every single pixel! In such situation you should create a symbol from a simple shape and display it multiple times instead. You will learn more about symbols in the following chapters. For now, just assume that you will be able to display hundreds of thousands of symbols without any significant slowdown. However, do not afraid to combine several primitives together in order to define a fancy shape! The rule of thumb is that if you define how your "component" looks like, use shapes, if you display many components, use symbols. Drawing a button or a flower shape should not affect a performance at all. However, if you want to display a plot with millions of dots, create a dot shape, convert it to shape and display the shape as each plot point. If you have any doubts, performance tests are always the best answer!


## Defining Shapes

Shapes are algebraic entities. It means that you can add, subtract or multiply shapes together. You can also apply many effects, like `grow`, `shrink`, `blur`, `bend` and combine results with other shapes. Shapes are more than just pictures. They can change - affect your cursor or animate with time! Keep in mind however, that all shapes transformations will be done on GPU, not on CPU and they will be automatically converted to GPU code by BaseGL. 

Unfortunately, neither JavaScript nor any of its sugar-languages (CoffeeScript, TypeScript, etc) allow for operator overloading, which makes using math libraries a big pain. It would be much better to write `(circle(zoom * 2) - circle(50)) * box(40,20)` than `circle(multiply(zoom,2)).subtract(circle(50)).multiply(box(40,20))`. BaseGL allows you to use several APIs to handle this issue.

### Shapes EDSL
BaseGL uses a simple trick to enable contextual operator overloading when defining shapes. While developing BaseGL we have created a small library which parses the body of a function and replaces all operators with corresponding functions. This way you can enable operator overloading on demand. We strongly encourage you to use it, because it makes shapes definition a breeze. You can of course use the "pure" API instead. 

You can use one of two forms of the EDSL - either as a pre-processor or as runtime library:

Let's create a first shape, a ring, by subtracting two circles using the pre-processor syntax:

```coffeescript
import {circle} from 'basegl/display/Shape'

`basegl.expr
myShape = do ->
  circle(100) - circle(80)
`
```

...and using the run-time syntax:

```coffeescript
myShape = basegl.expr do ->
  circle 100 - circle 80
```

...and using the run-time-eval syntax:

```coffeescript
myShape = eval basegl.localExpr do ->
  circle 100 - circle 80
```

We recommend to use the pre-processor utility whenever possible, because some environments could block usage of `eval`, which run-time functions have to use. The `basegl.expr` function takes a lambda as argument, converts it code, replaces all operators with appropriate functions, converts it back to JavaScript and evaluates the result. Magic.

The `localExpr` function works just like `expr`, however it lets you call `eval` by yourself. This way it has access to local variables outside the function. Do not be afraid of `eval` here. `Eval` could be evil if used in untrusted code - code that is not written by you. However if you are using eval only to evaluate the code generated by yourself in a very well defined place, you are safe. Said that, use pre-processor whenever possible.

## Your first shapes!
Let's create a simple shape, convert it to symbol and display on the screen!

```coffeescript
import * as basegl from 'basegl'
import {circle}    from 'basegl/display/Shape'

`basegl.expr
myShape = do ->
  (circle(100) - circle(80)).move(100,100)
`
mySymbol  = basegl.symbol myShape
mySymbol1 = scene.add mySymbol

```
That's it! You should see a red ring on your screen!

![](https://user-images.githubusercontent.com/1623053/35360399-df0116b6-015d-11e8-9b59-9b98577487d0.png)


Ok, let's create something more exciting. Four circles! Four circles is the most exciting thing I can currently imagine:

```coffeescript
myShapeF = eval basegl.localExpr () ->
  base = circle(100) + circle(100).moveX(100) + circle(100).move(50,50) + circle(100).move(50,-50)
  base.fill(Color.rgb [0,0,0,1]).move(200,250)
```
![](https://user-images.githubusercontent.com/1623053/35364482-b551218c-016f-11e8-8496-46c1f15cff4c.png)

BaseGL provides extensible debugging tools allowing you to inspect the shapes and understand the underlying SDF. You will learn more about the tools in the following chapters, for now just press <kbd>ctrl</kbd> + <kbd>alt</kbd> + <kbd>1</kbd>:

![](https://user-images.githubusercontent.com/1623053/35364610-5ff85cae-0170-11e8-8ab2-2bca26dc0a22.png)

This is visualisation of your shape SDF field. Blue part is inside, the violet part is outside the shape. By looking at the visualisation you can understand how `grow` and `shrink` functions work - they just allow you to grow or shrink the blue part. Let's move the circles further outside, shrink our shape a little bit and subtract it from the original one!

```coffeescript
myShapeF = eval basegl.localExpr () ->
  base = circle(100) + circle(100).moveX(160) + circle(100).move(80,80) + circle(100).move(80,-80)
  border = base - base.shrink(16)
  border.fill(Color.rgb [0,0,0,1]).move(170,250)
```

![](https://user-images.githubusercontent.com/1623053/35364798-71898b18-0171-11e8-89b7-bc2fece615ae.png)

BaseGL provides you with dozens combinators and different options. The `+` operator is alias for `Shape.union`. You can for example use `Shape.unionRound` instead to round corners when merging any shapes together! 

```coffeescript
myShapeF = eval basegl.localExpr () ->
  base = circle(100) + circle(100).moveX(160) + circle(100).move(80,80) + circle(100).move(80,-80)
  border = base - base.shrink(16)
  border.fill(Color.rgb [0,0,0,1]).move(170,250)
```
![](https://user-images.githubusercontent.com/1623053/35364953-3d20365a-0172-11e8-8fcf-292a097e44b5.png)


## Parametric and dynamic shapes
As we already mentioned, shapes are rendered on your GPU. It does not however mean that they have to be static images! You can both parametrize shapes with your own variables as well as use predefined ones:

| Variable name     | Description  |
| ----------------- |:------------ |
| `time`            | The number of miliseconds between creation of the Scene and current time. |
| `zoom`            | The camera zoom. The value of 1 mean that one shape unit corresponds to one pixel on the screen |
