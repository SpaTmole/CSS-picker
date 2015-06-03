class Debugger
    constructor: (debug)->
        @debug = debug

    printDecorator = (fn, cond)->
        if cond
            fn()

    print: (fn, args)->
        printDecorator ()->
            fn.apply console, args
        , @debug

    log: ()->
        args = Array.prototype.slice.call(arguments)
        @print console.log, args

    error: ()->
        args = Array.prototype.slice.call(arguments)
        @print console.error, args

    info: ()->
        args = Array.prototype.slice.call(arguments)
        @print console.info, args
