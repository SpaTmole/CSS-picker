class TemplateParser
    # Class which is supposed to parse following rules:
    # {{ key.name.<...>.final }}
    # {% for x in y %} ... {{x}} ... {%endfor%}  -Note, that it is supposed to be flat FORIN, there shouldn't be same rules inside
    constructor: (raw_data)->
        @html = raw_data

    prepareFinal: (object)->
        ###
        Classmethod joins all rules into one sheet and returns them grouped by media
        ###
        res = all: {}
        re_important = /.*!\s*important/i
        for rule in object.rules
            if !res[rule.media]
                res[rule.media] = {}
            for prop in rule.properties
                if !res[rule.media][prop] or !res[rule.media][prop].match(re_important) or rule.properties[prop].match(re_important)
                    res[rule.media][prop] = rule.properties[prop]

        for style of object.styles
            if !res['all'][style] or !res['all'][style].match(re_important) or object.styles[style].match(re_important)
                res['all'][style] = object.styles[style]
        res

    render: (object)->
        ###
        Method injects context which is passed within @object into initiated @this.html code
        ###
        render = $(@html)
        object = object.data
        render.find('.modal-header .dom-element').html(object.element)
        col1 = $("<div class='ext-col1'></div>")
        col2 = $("<div class='ext-col2'></div>")
        ul_styles = $("<ul class='ext-styles'></ul>")
        ul_attrs = $("<ul class='ext-attrs'></ul>")
        ul_rules = $("<ul class='ext-rules'></ul>")
        for style of object.styles
            ul_styles.append $("<li class='ext-style'><span class='ext-style-name'>#{style}: </span><span class='ext-style-value'>#{object.styles[style]}</span></li>")

        for attr of object.attributes
            ul_attrs.append $("<li class='ext-attribute'><span class='ext-attr-name'>#{attr}: </span><span class='ext-attr-value'>#{object.attributes[attr]}</span></li>")

        for rule in object.rules
            li = $('<li class="ext-css-rule"></li>')
            header = $("<div class='ext-css-rule-header'></div>")
            header.append $("<div><b>Media: </b><span>#{rule.media}</span></div>")
            header.append $("<div class='ext-css-rule-selector' title=\'#{rule.selector}\'>#{rule.selector}</div>")
            body = $("<ul class='ext-css-rule-props'></ul>")
            for prop of rule.properties
                body.append $("<li><div class='ext-css-rule-prop-key'>#{prop}: </div><div class='ext-css-rule-prop-val'>#{rule.properties[prop]}</div></li>")
            li.append(header).append(body)
            ul_rules.append(li)
        col1.append(ul_styles).append(ul_attrs).append(ul_rules)

        final_list_of_rules = @prepareFinal(object)   # TODO: Doesn't work properly!!!
        col2.append $("<h3>Final list of statements:</h3>")
        ul_statements = $("<ul class='ext-final-statements'></ul>")
        for media of final_list_of_rules
            ul_content_rules = $("<ul></ul>")
            for rule of final_list_of_rules[media]
                ul_content_rules.append $("<li><b>#{rule}: </b><span>#{final_list_of_rules[media][rule]}</span></li>")
            ul_statements.append("<p>@media #{media} {</p>").append(ul_content_rules).append("<p>}</p>")
        col2.append ul_statements
        render.find('.modal-body').append(col1).append(col2)

        render.wrap('<p></p>').parent().html()


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
                        url = request.url
                        xhr.open "GET", url, yes
                        xhr.onreadystatechange = ()->
                            if xhr.readyState is 4
                                sendRequest
                                    message: "loadExternalAsset"
                                    data: xhr.responseText
                                    url: url
                        xhr.send()


loadTemplate = (template_name)->
    $.ajax
        url: chrome.extension.getURL("templates/#{template_name}.html")
        type: 'GET'
        dataType: 'html'
        success: (data)->
            console.log "Loaded #{template_name}.html - #{data.length}"
