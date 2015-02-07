class StyleParser
    constructor: (item)->
        @element = item
        @rules = []
        @styles = {}
        @attributes = {}

    matchElement: (css_selector)->
        if $(@element)[0] in $(css_selector)
            return yes
        css_selector = css_selector.split(':')
        if $(@element)[0] in $(css_selector[0])
            return yes
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
            for rule in sheet.cssRules
                straightFetch rule

    getCustomStyles: ->
        @styles = @parseRules $(@element).attr 'style'
        @attributes = {}
        attributes = $(@element)[0].attributes
        for attribute in attributes
            if attribute.name isnt 'style'
                @attributes[attribute.name] = attribute.value
        return

    parseRules: (rules_str) ->
        result = {}
        rules_array = rules_str.split ';'
        for token in rules_array
            if token.length > 0
                named_value = token.split ':'
                name = named_value[0]
                named_value[0] = ""
                value = named_value.join ""
                result[name] = value
        result


$(document).ready ()->
    parser = null
    chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
        message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
        if request.csrf == message_bus_uuid
            console.log 'Data Recieved: ', request.data, parser
            $(parser.element).css({'border': 'solid 3px red'})
            # Here we need to make callback to extension, which will open Modal dialog.

    $(window).on('mousedown', (e)->
        if e.button is 2
            parser = new StyleParser e.toElement
    )
