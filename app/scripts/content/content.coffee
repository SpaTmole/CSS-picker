class StyleParser
    constructor: (item)->
        @element = item
        @rules = []
        @styles = {}
        @attributes = {}

    matchElement: (css_selector)->
        if $(@element)[0] in $(css_selector)
            return yes
        selectors_set = css_selector.split(',')
        for selector in selectors_set
            selector = selector.split(':')[0]
            try
                if $(@element)[0] in $(selector)
                    return yes
            catch wrong_selector
                console.error "Invalid selector: ", selector, " from ", {selector: css_selector}
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
            console.info("Attaching external stylesheet...")
            $(stylesheet).insertAfter $('script').first()
        for sheet in document.styleSheets
            if sheet.cssRules? and !sheet.extCSSPickerAdvancedPropVisited
                for rule in sheet.cssRules
                    straightFetch rule
            sheet.extCSSPickerAdvancedPropVisited = false
        for stylesheet in temp_stylesheets
            console.info("...Detaching external stylesheet")
            $(stylesheet).remove()

        return @

    getCustomStyles: ->
        @styles = @parseRules $(@element).attr('style') or ""
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
            return console.error "Template <#{template_name}> does not exist."
        binding_elem = $(template).find($(element))
        if !binding_elem
            return console.error "Couldn't find given element within <#{template_name}> template."
        return $(binding_elem).on 'click', fn

    render: (name) ->
        template = @get(name)
        if !template
            return console.error "Template <#{name}> does not exist."
        $(template).appendTo($('body'))

    dismiss: (name) ->
        template = @get(name)
        if !template
            return console.error "Template <#{name}> does not exist."
        $(template).detach()

    destroy: (name) ->
        template = @get(name)
        if !template
            return console.error "Template <#{name}> does not exist."
        $(template).remove()
        delete @templates[name]


class ExternalResourceKeeper
    constructor: (delegate_request)->
        @storage = {}
        for sheet in document.styleSheets
            if !sheet.cssRules and sheet.href
                delegate_request url: sheet.href, message: 'loadExternalAsset'

$(document).ready ()->
    parser = null
    result = null
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    viewController = new TemplateHandler()
    port = chrome.runtime.connect name: message_bus_uuid
    sendRequest = ((csrf)->
        return (args)->
            args.csrf = csrf
            return port.postMessage args
    )(message_bus_uuid)
    external_resources = new ExternalResourceKeeper(sendRequest)
    port.onMessage.addListener (request) ->
        if request.csrf == message_bus_uuid
            if request.message == "inspectWithContextMenu"
                console.log 'Data Recieved: ', request.data
                result = parser.invoke(external_resources)
                console.log "CSS: ", result
                sendRequest
                    message: "loadTemplate"
                    name: "modal"
                    data: result
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
                console.log "External asset loaded", request
                external_resources.storage[request.url] = request.data



    $(window).on('mousedown', (e)->
        if e.button is 2
            parser = new StyleParser e.toElement
    )
