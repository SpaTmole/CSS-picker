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
                console.error "Invalid selector: ", selector, " from ", css_selector
        return no

    fetchStyleSheetRules: ->
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

        for sheet in document.styleSheets
            if sheet.cssRules?
                for rule in sheet.cssRules
                    straightFetch rule
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

    invoke: ()->
        @getCustomStyles().fetchStyleSheetRules()
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

$(document).ready ()->
    parser = null
    chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
        message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
        if request.csrf == message_bus_uuid
            console.log 'Data Recieved: ', request.data
            result = parser.invoke()
            console.log "CSS: ", result
            sendResponse(
                data: result
                type: "styles"
                csrf: message_bus_uuid
            )

            # Here we need to make callback to extension, which will open Modal dialog.

    $(window).on('mousedown', (e)->
        if e.button is 2
            parser = new StyleParser e.toElement
    )
