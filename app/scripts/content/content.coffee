if !@Debugger
    class _Debugger
        log: ()->
        error: ()->
        info: ()->
else
    _Debugger = Debugger

window.chromeExtCSSPickerDebugLogger = new _Debugger(yes)

class StyleParser
    constructor: (item)->
        @element = item
        @rules = []
        @styles = {}
        @attributes = {}

    matchElement: (css_selector)->
        try
            if $(@element)[0] in $(selector)
                return yes
        catch wrong_selector
            chromeExtCSSPickerDebugLogger.error "Invalid selector: ", selector, " from ", {selector: css_selector}
        selectors_set = css_selector.split(',')
        for selector in selectors_set
            selector = selector.split(':')[0]
            try
                if $(@element)[0] in $(selector)
                    return yes
            catch wrong_selector
                chromeExtCSSPickerDebugLogger.error "Invalid selector: ", selector, " from ", {selector: css_selector}
        return no

    fetchStyleSheetRules: (external)->
        straightFetch = (rule, media="all") =>
            if rule.selectorText? and @matchElement rule.selectorText
                own_rule =
                    media: media
                    selector: rule.selectorText
                    properties: @parseRules rule.style.cssText
                @rules.push own_rule
            else if rule.media? and rule.media.length > 0 and rule.cssRules and rule.cssRules.length > 0
                for _rule in rule.cssRules
                    straightFetch _rule, rule.media.mediaText

        temp_stylesheets = []
        parsed_external_sheets = []
        for sheet in document.styleSheets
            if sheet.cssRules?
                if sheet.cssRules.length and sheet.cssRules[0].cssText.indexOf('#adPosition0') is -1
                # Sorry AdBlock, we aren't looking for you
                    for rule in sheet.cssRules
                        straightFetch rule
            else if sheet.href and !(sheet.href in parsed_external_sheets)
                raw_sheet = external.storage[sheet.href] or ''
                if raw_sheet.length
                    temp_id = "ChromeExtCSSPickerTemporaryExternalResourceAsset_#{temp_stylesheets.length}"
                    temp_style = $("<style id='#{temp_id}'>" + raw_sheet + '</style>')
                    temp_stylesheets.push(temp_style)
                    parsed_external_sheets.push sheet.href
            sheet.extCSSPickerAdvancedPropVisited = true
        for stylesheet in temp_stylesheets
            chromeExtCSSPickerDebugLogger.info("Attaching external stylesheet...")
            $(stylesheet).insertAfter $('script').first()
        for sheet in document.styleSheets
            if sheet.cssRules? and !sheet.extCSSPickerAdvancedPropVisited
                for rule in sheet.cssRules
                    straightFetch rule
            sheet.extCSSPickerAdvancedPropVisited = false
        for stylesheet in temp_stylesheets
            chromeExtCSSPickerDebugLogger.info("...Detaching external stylesheet")
            $(stylesheet).remove()

        return @

    getCustomStyles: ->
        @styles = @parseRules(($(@element).attr('style') or "").replace(/^[\s\n\t]+/, "").replace(/[\s\n\t]$/, ""))
        @attributes = {}
        attributes = $(@element)[0].attributes
        for attribute in attributes
            if attribute.name isnt 'style'
                @attributes[attribute.name] = attribute.value
        return @

    parseRules: (rules_str) ->
        result = {}
        rules_array = rules_str.split ';'
        for token in rules_array
            if token.length > 0
                named_value = token.split ':'
                name = @removeIndentation named_value[0]
                named_value[0] = ""
                value = named_value.join ""
                result[name] = @removeIndentation value
        result

    invoke: (external)->
        @getCustomStyles().fetchStyleSheetRules(external)
        element: @pretifyElement()
        styles: @styles
        attributes: @attributes
        rules: @rules

    pretifyElement: ->
        classes = ""
        for cls in @element.classList
            classes += ".#{cls}"
        return "#{@element.tagName.toLowerCase()}#{classes}"

    removeIndentation: (string) ->
        if string[0] == " "
            string = string.slice(1)
        if string[string.length - 1] == " "
            string = string.slice(0, string.length - 1)
        string


class TemplateHandler
    constructor: ->
        @templates = {}

    get: (name)->
        return @templates[name] or null

    set: (name, code) ->
        if @templates[name]?
            @destroy(name)
        @templates[name] = code

    bind: (template_name, element, fn) ->
        template = @get(template_name)
        if !template
            return chromeExtCSSPickerDebugLogger.error "Template <#{template_name}> does not exist."
        binding_elem = $(template).find($(element))
        if !binding_elem
            return chromeExtCSSPickerDebugLogger.error "Couldn't find given element within <#{template_name}> template."
        return $(binding_elem).on 'click', fn

    render: (name) ->
        template = @get(name)
        if !template
            return chromeExtCSSPickerDebugLogger.error "Template <#{name}> does not exist."
        $(template).appendTo($('body'))

    dismiss: (name) ->
        template = @get(name)
        if !template
            return chromeExtCSSPickerDebugLogger.error "Template <#{name}> does not exist."
        $(template).detach()

    destroy: (name) ->
        template = @get(name)
        if !template
            return chromeExtCSSPickerDebugLogger.error "Template <#{name}> does not exist."
        $(template).remove()
        delete @templates[name]


class ExternalResourceKeeper
    constructor: (delegate_request)->
        @storage = {}
        @processing = 0
        for sheet in document.styleSheets
            if !sheet.cssRules and sheet.href
                @processing += 1
                delegate_request url: sheet.href, message: 'loadExternalAsset'

$(document).ready ()->
    parser = null
    result = null
    app_enabled = yes
    hotkey = ""
    message_bus_uuid = "2151ada6-a6eb-447c-82b9-0b3f30d0aff4-#{Math.random().toFixed(7) * 10000000}"
    viewController = new TemplateHandler()
    port = chrome.runtime.connect name: message_bus_uuid
    sendRequest = ((csrf)->
        return (args)->
            args.csrf = csrf
            return port.postMessage args
    )(message_bus_uuid)
    hotkeyInspection = (()->
        GetAllElementsAt = (x, y) ->
            $elements = $("body *").map(()->
                #TODO:  add positioning by getClientRect and correct offset with scrollX(Y)
                offset = @.getBoundingClientRect()
                l = offset.left; #+ window.scrollX;
                r = offset.right; #+ window.scrollX;
                t = offset.top; #+ window.scrollY;
                b = offset.bottom; #+ window.scrollY;

                if (y <= b and y >= t) and (x <= r and x >= l)
                    $(@)
                else
                    null
            )
            return $elements

        inspectionToggle = no
        offscreen = $("<div id='extCssPickerOffscreenSelection'></div>")
        offscreen.css
            position: 'absolute',
            'z-index': 999999,
            opacity: 0.45,
            background: 'pink'
        target = null
        $(window).on('click', ()->
            if inspectionToggle and app_enabled
                $(offscreen).detach()
                inspectionToggle = no
                if app_enabled
                    parser = new StyleParser target
                    result = parser.invoke(external_resources)
                    chromeExtCSSPickerDebugLogger.log "CSS: ", result
                    sendRequest
                        message: "loadTemplate"
                        name: "modal"
                        data: result
        )
        ()->
            inspectionToggle = !inspectionToggle
            if inspectionToggle and app_enabled
                $('html').append(offscreen)
                $(window).on('mousemove', (e)->
                    if inspectionToggle and app_enabled
                        elementsMouseIsOver = GetAllElementsAt e.clientX, e.clientY
                        selectedElement = null
#                        _indexOfLast = elementsMouseIsOver.length - 1
#                        selectedElement = elementsMouseIsOver[_indexOfLast]
#                        while (selectedElement.id is "extCssPickerOffscreenSelection" or selectedElement.css('display') is 'none') and _indexOfLast > 0
#                            _indexOfLast -= 1
#                            selectedElement = elementsMouseIsOver[_indexOfLast]
                        max_depth = 0;
                        $.each(elementsMouseIsOver, (_i1, el)->
                            _max_depth = $(el).parents().length;
                            if max_depth < _max_depth and $(el).css('display') isnt 'none'
                                max_depth = _max_depth
                                selectedElement = el
                        )

                        target = selectedElement[0]
                        #                        chromeExtCSSPickerDebugLogger.log "under selection ", target
                        client_rect = target.getBoundingClientRect()
                        offscreen.css
                            height: client_rect.bottom - client_rect.top
                            left: client_rect.left + window.scrollX
                            top: client_rect.top + window.scrollY
                            width: client_rect.right - client_rect.left
                            'z-index':  0
                )
            else
                offscreen.detach()
    )()
    external_resources = new ExternalResourceKeeper(sendRequest)
    port.onMessage.addListener (request) ->
        if request.csrf == message_bus_uuid
            if app_enabled
                if request.message == "inspectWithContextMenu"
                    chromeExtCSSPickerDebugLogger.log 'Data Recieved: ', request.data
                    if request.data.enabled
                        result = parser.invoke(external_resources)
                        chromeExtCSSPickerDebugLogger.log "CSS: ", result
                        sendRequest
                            message: "loadTemplate"
                            name: "modal"
                            data: result
                    else
                        app_enabled = no
                    return
                if request.message == 'loadTemplate'
                    if request.name == 'modal'
                        viewController.set request.name, request.data
                        modal = viewController.render(request.name)
                        modal.modal('show')
                        modal.on('hidden.bs.modal', ()->
                            $(modal).remove()
                        )
                if request.message is "loadExternalAsset"
                    chromeExtCSSPickerDebugLogger.log "External asset loaded", request
                    external_resources.storage[request.url] = request.data
                    external_resources.processing -= 1

            if request.message is "enableInspection"
                app_enabled = yes

            if request.message is "disableInspection"
                app_enabled = no

            if request.message is "setupShortcut"
                Mousetrap.unbind hotkey
                hotkey = request.data
                Mousetrap.bind(hotkey, ()->
                    hotkeyInspection()
                )
            if request.message is "appStatus"
                app_enabled = request.data
                hotkey = request.advanced.hotkey
                Mousetrap.bind(hotkey, ()->
                    hotkeyInspection()
                )
    sendRequest
        message: "appStatus"

    $(document).mousedown (e)->
        if app_enabled
            if e.button is 2
                parser = new StyleParser e.toElement
