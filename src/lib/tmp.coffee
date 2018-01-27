

class MyShader
  constructor: () ->
    @uniforms =
      tDiffuse:  { value: null }
      h:         { value: 1000.0 / 512.0 }
      zoomSpeed: { value: 0 }
      zoomUV:    { value: (new THREE.Vector2 0,0)}
      pan:       { value: (new THREE.Vector2 0,0)}
      vel:       { value: (new THREE.Vector3 0,0,0)}

    @vertexShader = """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }"""

    @fragmentShader = """

    uniform sampler2D tDiffuse;
    uniform float h;
    uniform float zoomSpeed;
    uniform vec2  zoomUV;
    uniform vec3  vel;

    varying vec2 vUv;

    void main() {

      vec4 sum  = vec4( 0.0 );
      vec2 zoom = vUv - zoomUV;
      // float hx  = h * (zoomUV.x + zoom.x * abs(zoomUV.z));
      // float hy  = h * (zoomUV.y + zoom.y * abs(zoomUV.z));

      // float hx  = h * zoom.x * zoomSpeed;
      // float hy  = h * zoom.y * zoomSpeed;

      float hx  = h * (vel.z * (vUv.x - 0.5) + vel.x);
      float hy  = h * (vel.z * (vUv.y - 0.5) + vel.y);


      sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * hx, vUv.y - 4.0 * hy ) ) * 2.0 * 0.051;
      sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * hx, vUv.y - 3.0 * hy ) ) * 2.0 * 0.0918;
      sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * hx, vUv.y - 2.0 * hy ) ) * 2.0 * 0.12245;
      sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * hx, vUv.y - 1.0 * hy ) ) * 2.0 * 0.1531;
      sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 1.0;
      // sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * hx, vUv.y + 1.0 * hy ) ) * 0.1531;
      // sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * hx, vUv.y + 2.0 * hy ) ) * 0.12245;
      // sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * hx, vUv.y + 3.0 * hy ) ) * 0.0918;
      // sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * hx, vUv.y + 4.0 * hy ) ) * 0.051;

      gl_FragColor = sum;
      // gl_FragColor = vec4(vUv.x, vUv.y, 0.0, 1.0);
      // gl_FragColor = vec4(zoom.x, zoom.y, 0.0, 1.0);

    }"""


    # hblur.uniforms.zoomSpeed.value = @vel.z #



# ia kamery - version - przy renderowaniu gdy zmienila sie version, przeliczamy "updateProjectionMatrix"
#   mozna zrobic podobnie z obiektami na scenie - zamiast przeliczac ich pozycje po kazdej zmianie, robic to przed renderowaniem
#   ustawiajac na obiekcie i kazdym jego parencie "dirty position". Mozna ponadto latwo rejestrowac dirty position children w tablicy - bo jak dziecko bylo dirty
#   to nie musimy go dodawac, wiec nie trzeba nawet uzywac setu.
#
#   To sa 2 mechanizmy - hierarchiczny dirty i wersja. Mozliwe ze po kilka znich bedzie uzywanych per obiekt dla roznych ustawien. Pozycje hierarhciczne licza matrix obiektu. ustawienia kamery
#   licza matrix oka.
#
#   musimy miec wrapper GLCamera, ktory handluje kamery per Viewer. Jezeli renderujemy i taki GLCamera ma inna wersje niz jego ref, wtedy odswiezamy
#   zeby nie bawic sie overflow, moze da sie wersje zrobic jako bool i po przejsciu przez cala scene i wszystkie viewer ustawiac ja na false?
#
#   ponadto, minimapka powinna byc zrobiona jako - 1 scena, 2 widoki, 2 kamery, przy czym jedna kamera dzieckiem drugiej?
#   zaleznie od wygladu minimapki, bo moze tez byc statyczna kamera z prostokatem pokazujacym gdzie jestesmy, tak czy siak,
#   hierarchicznosc na kamerach jest supe
