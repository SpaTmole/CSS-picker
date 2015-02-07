gulp        = require "gulp"
coffee      = require "gulp-coffee"
gutil       = require "gulp-util"
coffeelint  = require "gulp-coffeelint"
sass        = require "gulp-sass"
uglify      = require "gulp-uglify"
lib         = require('bower-files')()
#karma       = require "gulp-karma"
del         = require "del"
concat      = require "gulp-concat"
#preen       = require "preen"
lintspaces  = require "gulp-lintspaces"


dev  = "./app"

path =
    coffee:
        bg: "#{dev}/scripts/background/*.coffee"
        content: "#{dev}/scripts/content/*.coffee"
    js:
        bg: "#{dev}/js/bg/"
        content: "#{dev}/js/content/"
    scss: "#{dev}/styles/scss/*.scss"
    css: "#{dev}/styles/css"
#    test:

options =
    lintspaces: {
                newline: yes
                newlineMaximum: 2
                indentation: 4
                spaces: 4
                }

gulp.task "coffee_lint", () ->
    gulp.src([path.coffee.bg, path.coffee.content])
        .pipe(coffeelint({indentation: 4}))
        .pipe(coffeelint.reporter())


gulp.task "lintspaces", () ->
    gulp.src([path.coffee.bg, path.coffee.content])
        .pipe(lintspaces(options.lintspaces))
        .pipe(lintspaces.reporter())


gulp.task "coffee", ["coffee_lint", "lintspaces"], () ->
    gulp.src(path.coffee.bg)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.bg))
    gulp.src(path.coffee.content)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.content))


gulp.task "concat_bg", ["coffee"], () ->
    gulp.src(["#{dev}/js/bg/*.js"])
        .pipe(concat("app.js"))
        .pipe(gulp.dest(""))

gulp.task "concat_content", ["coffee"], () ->
    gulp.src(["#{dev}/js/content/*.js"])
        .pipe(concat("content.js"))
        .pipe(gulp.dest(""))

gulp.task "build_app", ["concat_bg", "concat_content"], () ->
    del(["#{dev}/js/"])  # place here all excess js files

gulp.task 'concat_bower', () ->
  gulp.src lib.ext('js').files
    .pipe(concat('lib.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest(''))

gulp.task "sass", () ->
    gulp.src(path.scss)
        .pipe(sass())
        .pipe(gulp.dest(path.css))

gulp.task "build", ["build_app", "concat_bower", "sass"]


#gulp.task "test", ["build", "karma"]

#gulp.task "watch", () ->
#    gulp.watch(path.coffee, ["build"])
#    gulp.watch(path.scss, ["sass"])
