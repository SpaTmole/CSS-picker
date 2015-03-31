class TemplateParser
    # Class supposed to parse rules within template as following: {{ key.name.<...>.final }}
    constructor: (raw_data)->
        @html = raw_data

    render: (object)->
        render = "#{@html}"
        keys = $.map(object, (el, key)->return [key])
        for key in keys
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
                        data = object[key]
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
        #Clear mismatched tags
        while match = render.match /\{\{.*?\}\}/
            render = render.replace match[0], ''
        render


chrome.runtime.onInstalled.addListener ()->
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    chrome.contextMenus.create
            title: "Inspect element style",
            id: "chromeExtCssPickerContextMenuInspectorItem",
            contexts: ["all"]
    chrome.contextMenus.onClicked.addListener (info, tab) ->
        if info.menuItemId == "chromeExtCssPickerContextMenuInspectorItem"
            console.log 'Inspecting element: ', arguments
            chrome.tabs.query {active: yes, currentWindow: yes}, (tabs) ->
                tabId = tabs[0].id
                chrome.tabs.sendMessage tabId,
                    {
                        message: 'inspectWithContextMenu'
                        csrf: message_bus_uuid
                    },
                    (response) ->
                        console.log response
                        if response.message == "loadTemplate"
                            loadTemplate(response.name).done (html)->
                                templateParser = new TemplateParser html
                                chrome.tabs.sendMessage tabId,
                                    message: 'loadTemplate'
                                    name: response.name
                                    csrf: message_bus_uuid
                                    data: templateParser.render(data: response.data)
                                , (response) ->
                                    console.log 'After template\'s loaded'
        return

loadTemplate = (template_name)->
    $.ajax
        url: chrome.extension.getURL("templates/#{template_name}.html")
        type: 'GET'
        dataType: 'html'
        success: (data)->
            console.log "Loaded #{template_name}.html - #{data.length}"
