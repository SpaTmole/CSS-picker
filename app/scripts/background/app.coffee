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
            if !res[rule.media][rule.selector]
                res[rule.media][rule.selector] = {}
            for prop of rule.properties
                if !res[rule.media][rule.selector][prop] or !res[rule.media][rule.selector][prop].match(re_important) or rule.properties[prop].match(re_important)
                    res[rule.media][rule.selector][prop] = rule.properties[prop]

        for style of object.styles
            res['all'][object.element] = res['all'][object.element] or {}
            if !res['all'][object.element][style] or !res['all'][object.element][style].match(re_important) or object.styles[style].match(re_important)
                res['all'][object.element][style] = object.styles[style]
        res

    _splitBySelectorProps = (selectors, elem) ->
        ###
        Private function receives list of CSS props grouped by media and selectors, returns list of those props
        grouped by :selector_attrs
        ###
        res = {}
        source_classes = elem.split '.'
        _match_q = (selector)->
            ###
            Function matches if source element's class-queue might be nested with given selector.
            ###
            selector_class_q = selector.replace(/:.*/gi, '').split '.'
            #TODO: Beware of hidden bug: a.not(:hover).class.queue.continues
            #TODO: Here is example how to exclude such patterns (needed to adjust): http://stackoverflow.com/questions/2078915/a-regular-expression-to-exclude-a-word-string

            if !selector_class_q[0]
                selector_class_q.shift()
            else if selector_class_q[0] isnt source_classes[0]
                return no
            for token in selector_class_q
                if source_classes.indexOf(token) is -1
                    return no
            return yes

        for media of selectors
            for selector of selectors[media]
                for sub_s in selector.replace(/\s*?,\s*?/img, ',').split ","
                    sub_s = sub_s.replace(/(\+|~|>)/g, '').replace(/.*\s+/g, '')
                    if _match_q(sub_s)
                        final = sub_s.split(':').pop()
                        res[final] = res[final] or {}
                        to_update = {}
                        to_update[media] = {}
                        to_update[media][sub_s] = selectors[media][selector]
                        $.extend yes, res[final], to_update
        res

    renderFinal: (data, append_to)->
        ###
        Function-helper, which wraps data into tabs, splits by selectors and eventually appends to received elem;
        ###
        final_list_of_rules = @prepareFinal(data)
        grouped = _splitBySelectorProps(final_list_of_rules, data.element)
        append_to.append $("<h3>Final list of statements:</h3>")

        ul_navbar = $('<ul class="nav nav-tabs" role="tablist"></ul>')
        li_all = $('<li class="active" role="presentation"></li>')
        li_all.append $('<a href="#ext-CSSPicker-all" aria-controls="ext-CSSPicker-all" role="tab" data-toggle="tab">All</a>')
        ul_navbar.append li_all

        # -------------
        ul_statements = $("<ul class='ext-final-statements tab-content'></ul>")
        # TODO: Add preview.
        li_all = $('<li class="tab-pane active" id="ext-CSSPicker-all" role="tabpanel"></li>')
        for media of final_list_of_rules
            ul_content_rules = $("<ul></ul>")
            for selector of final_list_of_rules[media]
                selector_li = $("<li></li>")
                selector_li.append $("<p>#{selector} {</p>")
                for rule of final_list_of_rules[media][selector]
                    selector_li.append $("<p><b>#{rule}: </b><span>#{final_list_of_rules[media][selector][rule]};</span></p>")
                selector_li.append $("<p>}</p>")
                ul_content_rules.append selector_li
            li_all.append("<p>@media #{media} {</p>").append(ul_content_rules).append("<p>}</p>")
        ul_statements.append li_all
        for sel_class of grouped
            sel_class_safe = sel_class.replace ".", "class-"
            a_nav = $('<a href="#ext-CSSPicker-' +
                sel_class_safe + '" aria-controls="ext-CSSPicker-' + sel_class_safe + '" role="tab" data-toggle="tab">' +
                sel_class + '</a>')
            a_nav.wrap('<li role="presentation"></li>')
            ul_navbar.append a_nav.parent()
            li_tabpanel = $('<li role="tabpanel" class="tab-pane" id="ext-CSSPicker-' + sel_class_safe + '"></li>')
            for media of grouped[sel_class]
                li_tabpanel.append $("<p>@media " + media + " {</p>")
                for media_sel of grouped[sel_class][media]
                    li_tabpanel.append $("<p class='ext-padded'>" + media_sel + "{</p>")
                    for sel_prop of grouped[sel_class][media][media_sel]
                        li_tabpanel.append $("<p class='ext-padded'><p class='ext-padded'>" +
                            "<b>" + sel_prop + ": </b>" + "<span>" + grouped[sel_class][media][media_sel][sel_prop] +
                            ";</span></p></p>")
                    li_tabpanel.append $("<p class='ext-padded'>}</p>")
                li_tabpanel.append $("<p>}</p>")
            ul_statements.append li_tabpanel
        append_to.append ul_navbar
        append_to.append ul_statements
        return

    render: (object)->
        ###
        Method injects context which is passed within @object into initiated @this.html code
        ###
        render = $(@html)
        object = object.data
        render.find('.modal-header .dom-element').html @wrapClasses object.element
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
        if ul_styles.children().length
             col1.append("<h3>Styles:</h3>").append(ul_styles)
        if ul_attrs.children().length
             col1.append("<h3>Attributes:</h3>").append(ul_attrs)
        if ul_rules.children().length
             col1.append("<h3>CSS Rules:</h3>").append(ul_rules)
        @renderFinal(object, col2)
        render.find('.modal-body').append(col1).append(col2)
        render.wrap('<p></p>').parent().html()

    wrapClasses: (string)->
        res = $('<p></p>')
        string = string.split "."
        $.each(string, (ind, token)->
            if !ind
                res.append $("<strong>#{token}</strong>")
            else
                res.append $("<i>#{token}</i>")
            if ind isnt string.length - 1
                res.append "."
        )
        res.html()

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
