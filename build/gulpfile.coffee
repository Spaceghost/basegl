gulp      = require 'gulp'
coffee    = require 'gulp-coffee'
transform = require 'gulp-transform'
rename    = require 'gulp-rename'
plumber   = require 'gulp-plumber'
execSync  = require('child_process').execSync


cwd    = '..'
path   = (s) -> "#{cwd}/#{s}"
dist   = path 'dist'
pkgCfg = path 'package.json'


gulp.task 'transpile_coffee', (done) ->
  gulp.src (path 'src/**/*.coffee'), {sourcemaps: true}
    .pipe(plumber())
    .pipe coffee {bare: true}
    .pipe gulp.dest dist
  done()


gulp.task 'transpile_glsl', (done) ->
  gulp.src (path 'src/**/*.glsl')
    .pipe transform 'utf8', (str) => "var code = `\n#{str.replace(/`/g,"'")}`;\nexport default code;"
    .pipe rename (path) => path.extname = ".js"
    .pipe gulp.dest dist
  done()


gulp.task 'copy_package_config', (done) ->
  gulp.src pkgCfg
    .pipe gulp.dest dist
  done()


incVersionWith = (f) => (str) =>
  json    = JSON.parse(str)
  version = json.version.split '.'
  if version.length != 3 then throw "Incorrect version '#{json.version}'."
  version = (parseInt a for a in version)
  f version
  version = version.join '.'
  json.version = version
  JSON.stringify(json,null,2)

incVersionDev   = incVersionWith (version) => version[2] += 1
incVersionMinor = incVersionWith (version) => version[1] += 1; version[2] = 0
incVersionMajor = incVersionWith (version) => version[0] += 1; version[1] = 0; version[2] = 0

gulp.task 'incVersionDev', (done) ->
  gulp.src pkgCfg
    .pipe transform 'utf8', incVersionDev
    .pipe gulp.dest(cwd)
  done()

gulp.task 'incVersionMinor', (done) ->
  gulp.src pkgCfg
    .pipe transform 'utf8', incVersionMinor
    .pipe gulp.dest(cwd)
  done()

gulp.task 'incVersionMajor', (done) ->
  gulp.src pkgCfg
    .pipe transform 'utf8', incVersionMajor
    .pipe gulp.dest(cwd)
  done()

gulp.task 'build'   , gulp.series 'copy_package_config', 'transpile_coffee', 'transpile_glsl'
gulp.task 'default' , gulp.series 'build'
gulp.task 'publish' , gulp.series 'build', 'incVersionDev', 'copy_package_config', (done) ->
  done()

gulp.task 'publish:minor', gulp.series 'build', 'incVersionMinor', 'copy_package_config', (done) ->
  execSync "cd #{dist} && npm publish", {stdio:'inherit'}
  done()

gulp.task 'publish:major', gulp.series 'build', 'incVersionMajor', 'copy_package_config', (done) ->
  execSync "cd #{dist} && npm publish", {stdio:'inherit'}
  done()


gulp.task 'watch', gulp.series 'build', (done) ->
  gulp.watch (path 'src/**/*'), gulp.series('build')


gulp.task 'sandboxServer', (done) ->
  execSync "cd #{path 'examples'} && npx webpack-dev-server --open --env=sandbox", {stdio:'inherit'}
  done()


gulp.task 'sandbox', gulp.parallel 'watch', 'sandboxServer'
