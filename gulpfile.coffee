gulp        = require "gulp"
coffee      = require "gulp-coffee"
gutil       = require "gulp-util"
coffeelint  = require "gulp-coffeelint"
sass        = require "gulp-sass"
uglify      = require "gulp-uglify"
lib         = require('bower-files')(
    overrides:
        mousetrap:
            main: ['mousetrap.js', 'plugins/record/mousetrap-record.js']
            dependencies: {}
)

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
        options: "#{dev}/scripts/options/*.coffee"
    js:
        bg: "#{dev}/js/bg/"
        content: "#{dev}/js/content/"
        options: "#{dev}/js/options/"
    scss: "#{dev}/styles/scss/*.scss"
    css: "#{dev}/styles/css"
#    test:
    dest: "dest/"

options =
    lintspaces: {
                newline: yes
                newlineMaximum: 4
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


gulp.task "coffee_prod", ["coffee_lint", "lintspaces"], () ->
    gulp.src(path.coffee.bg)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.bg))
    gulp.src(path.coffee.content)
        .pipe(coffee({bare: no}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.content))
    gulp.src(path.coffee.options)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.dest))

gulp.task "coffee_debug", ["coffee_lint", "lintspaces"], () ->
    gulp.src(path.coffee.bg)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.bg))
    gulp.src(path.coffee.content)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.js.content))
    gulp.src(path.coffee.options)
        .pipe(coffee({bare: yes}).on("error", gutil.log))
        .pipe(gulp.dest(path.dest))

gulp.task "concat_bg", () ->
    gulp.src(["#{dev}/js/bg/*.js"])
        .pipe(concat("app.js"))
        .pipe(gulp.dest(path.dest))

gulp.task "concat_content", () ->
    gulp.src("#{dev}/js/content/content.js")
        .pipe(gulp.dest(path.dest))

gulp.task "build_app", ["coffee_prod"], ()->
    gulp.src(["#{dev}/js/bg/*.js"])
        .pipe(concat("app.js"))
        .pipe(gulp.dest(path.dest))
    gulp.src("#{dev}/js/content/content.js")
        .pipe(gulp.dest(path.dest))

gulp.task 'concat_bower', () ->
  gulp.src lib.ext('js').files
    .pipe(concat('lib.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest(path.dest))

gulp.task "sass", () ->
    gulp.src(path.scss)
        .pipe(sass())
        .pipe(gulp.dest(path.css))

gulp.task "styles", ["sass"], ->
    gulp.src(["#{path.css}/*.css"])
        .pipe(concat("content.css"))
        .pipe(gulp.dest(path.dest))
    gulp.src("#{dev}/images/*").pipe(gulp.dest(path.dest))
    #del("#{[path.css]}/")

gulp.task "production", ["build_app", "concat_bower", "styles"], ()->
    console.log "Deleting temporary files..."
    del(["#{dev}/js/"])  # place here all excess js files

gulp.task "debug", ["concat_bower", "styles", "coffee_debug", "concat_bg"], ()->
    gulp.src(["#{dev}/js/content/debugger.js", "#{dev}/js/content/content.js"])
        .pipe(concat("content.js"))
        .pipe(gulp.dest(path.dest))
    del(["#{dev}/js/"])

#gulp.task "test", ["build", "karma"]

#gulp.task "watch", () ->
#    gulp.watch(path.coffee, ["build"])
#    gulp.watch(path.scss, ["sass"])
