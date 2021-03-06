# cd node_modules/robotjs
# HOME=~/.electron-gyp node-gyp rebuild --target=0.37.8 --arch=x64 --dist-url=https://atom.io/download/atom-shell

gulp = require('gulp')
electron = require('electron-connect').server.create()
path = require('path')
exec = require 'gulp-exec'


gulp.task 'serve', [], ->
  electron.start ['app/app.js', 'develop',
  '--disable-http-cache',
  '--enable-transparent-visuals']
  gulp.watch 'app/**/*.coffee', ['electron-restart']
  # gulp.watch 'app/frontend/**/*.less', [ 'electron-reload' ]
  # gulp.watch 'src/frontend/**/*.cjsx', [ 'electron-reload' ]
  gulp.watch 'app/frontend/**/*.html', [ 'electron-restart' ]


gulp.task 'electron-reload', ->
  electron.reload()
  return

gulp.task 'electron-restart', ->
  electron.restart ['app/app.js','develop',
  '--disable-http-cache',
  '--enable-transparent-visuals']

electron.on 'appClosed', ->
  electron.stop ->
    process.exit 0
    return
  return

gulp.task 'default', [ 'serve' ]
