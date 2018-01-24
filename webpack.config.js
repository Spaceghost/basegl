var webpack = require('webpack');

const path = require('path');

module.exports =
  { entry: './main.coffee'
  , context: path.resolve(__dirname, "src")
  , output:
    { path: path.resolve(__dirname, 'dist', 'js')
    , publicPath: '/js/'
    , filename: 'basegl.js'
    , library: 'basegl'
    , strictModuleExceptionHandling: true
    }
  , node: {
      __filename: true,
      __dirname: true,
  },

  devtool: "eval-source-map",

  devServer: {
    contentBase: path.resolve(__dirname, 'dist')
  },

  resolve: {
      extensions: ['.js', '.coffee'],
      modules: [
        path.resolve(__dirname, "src"),
        "node_modules"
      ],
  	  alias: {
  	    'three/OrbitControls'        : path.join(__dirname, 'node_modules/three/examples/js/controls/OrbitControls.js'),
  	    'three/EffectComposer'       : path.join(__dirname, 'node_modules/three/examples/js/postprocessing/EffectComposer.js'),
  	    'three/CopyShader'           : path.join(__dirname, 'node_modules/three/examples/js/shaders/CopyShader.js'),
  	    'three/HorizontalBlurShader' : path.join(__dirname, 'node_modules/three/examples/js/shaders/HorizontalBlurShader.js'),
  	    'three/ShaderPass'           : path.join(__dirname, 'node_modules/three/examples/js/postprocessing/ShaderPass.js'),
  	    'three/RenderPass'           : path.join(__dirname, 'node_modules/three/examples/js/postprocessing/RenderPass.js'),
  	    'three/MaskPass'             : path.join(__dirname, 'node_modules/three/examples/js/postprocessing/MaskPass.js'),
  	  }
  },

  module:
    { strictExportPresence: true
    , rules:
      [ { use: 'coffee-loader'  , test: /\.(coffee)$/                                   }
      , { use: 'raw-loader'     , test: /\.(glsl|vert|frag)$/ , exclude: /node_modules/ }
      , { use: 'glslify-loader' , test: /\.(glsl|vert|frag)$/ , exclude: /node_modules/ }
      ]
    }
  , plugins:
    [ new webpack.ProvidePlugin({'THREE': 'three'})
    ]

};
