class TemplateParser
    # Class which is supposed to parse following rules:
    # {{ key.name.<...>.final }}
    # {% for x in y %} ... {{x}} ... {%endfor%}  -Note, that it is supposed to be flat FORIN, there shouldn't be same rules inside
    constructor: (raw_data)->
        @html = raw_data

    _for_in = (render, object)->
        ###
        Private static method which replaces within passed @render text all {% for in %} injections
        by values kept in @object which are expected to be iterable.
        ###
        result = render
        re = /\{%\s*?for\s+?.+?\s+?in\s+?.+?\s*?%}(.|\n)*?\{%\s*?endfor\s*?%}/gim
        keys = $.map(object, (el, key)->return [key])

        matches = render.match(re) or []
        for match in matches
            loop_render = ""
            for_in = match.match(/\{%\s*?for\s+?.+?\s+?in\s+?.+?\s*?%}/).shift()
            tokens = for_in.replace(/\{%\s*for\s*/, '').replace(/\s*%}.*/, '').replace(/\s+/, ' ').split(' in ')
            iterable_key = tokens[1].split('.')[0]
            if iterable_key in keys
                dots_separated = tokens[1].split('.')
                dots_separated.shift()
                data = (()->
                    data = object[iterable_key]
                    for token in dots_separated
                        if data[token]?
                            data = data[token]
                        else
                            return ""
                    return data
                )()
                if data
                    body = match.replace(/\{%\s*?for\s+?.+?\s+?in\s+?.+?\s*?%}/, '').replace(/\{%\s*?endfor\s*?%}/, '')
                    for key, value of data
                        loop_render += _brackets_substitution(body, tokens[0], value)
            result = result.replace(match, loop_render)
        result


    _brackets_substitution = (render, key, value) ->
        ###
        Private static method which replaces within passed @render text all {{ @key[.subval[]] }} injections by @value
        ###
        re = new RegExp "\{\{\ *#{key}.*?\}\}"
        results = []
        (()->
            _render = render
            while match = _render.match re
                results.push match[0]
                _render = _render.replace match[0], ''
        )()
        (()->
            for result in results
                dots_separated = result.replace(/\{\{\s*?/, "").replace(/\s*?\}\}/, "").split('.')
                dots_separated.shift() # Because we know first token
                data = (()->
                    data = value
                    for token in dots_separated
                        if data[token]?
                            data = data[token]
                        else
                            return ""
                    return data
                )()
                if data
                    render = render.replace(new RegExp(result, 'g'), data)
            return
        )()
        return render


    render: (object)->
        ###
        Method injects context which is passed within @object into initiated @this.html code
        ###
        render = "#{@html}"
        keys = $.map(object, (el, key)->return [key])
        render = _for_in(render, object)
        for key in keys
            render = _brackets_substitution(render, key, object[key])
        #Clear mismatched tags
        while match = render.match /\{\{.*?}}/
            render = render.replace match[0], ''
        render


chrome.runtime.onInstalled.addListener ()->
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    chrome.contextMenus.create
            title: "Inspect element style",
            id: "chromeExtCssPickerContextMenuInspectorItem",
            contexts: ["all"]

    chrome.runtime.onConnect.addListener (port) ->
        if port.name is message_bus_uuid
            console.log "Extension initiated: ", port
            sendRequest = ((csrf)->
                return (args)->
                    args.csrf = csrf
                    return port.postMessage args
            )(message_bus_uuid)
            chrome.contextMenus.onClicked.addListener (info, tab) ->
                if info.menuItemId == "chromeExtCssPickerContextMenuInspectorItem"
                    console.log 'Inspecting element: ', arguments
                    sendRequest
                        message: 'inspectWithContextMenu'
                return
            port.onMessage.addListener (request)->
                if request.csrf == message_bus_uuid
                    if request.message is "loadTemplate"
                        loadTemplate(request.name).done (html)->
                            templateParser = new TemplateParser html
                            sendRequest
                                message: 'loadTemplate'
                                name: request.name
                                data: templateParser.render(data: request.data)
                    if request.message is "loadExternalAsset"
                        xhr = new XMLHttpRequest()
                        xhr.open "GET", request.url, yes
                        xhr.onreadystatechange = ()->
                            if xhr.readyState is 4
                                sendRequest
                                    message: "loadExternalAsset"
                                    data: xhr.responseText
                        xhr.send()


loadTemplate = (template_name)->
    $.ajax
        url: chrome.extension.getURL("templates/#{template_name}.html")
        type: 'GET'
        dataType: 'html'
        success: (data)->
            console.log "Loaded #{template_name}.html - #{data.length}"
