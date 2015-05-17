$(document).ready ()->
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    port = chrome.runtime.connect name: message_bus_uuid
    sendRequest = ((csrf)->
        return (args)->
            args.csrf = csrf
            return port.postMessage args
    )(message_bus_uuid)
    port.onMessage.addListener (request) ->
        if request.csrf == message_bus_uuid
            if request.message is "appStatus"
                $("#enable-disable-label").text if request.data then "Enabled" else "Disabled"
                if request.data then $(".switch").attr('class', 'switch switchOn') else $(".switch").attr('class', 'switch')
            if request.message is "disableInspection"
                $(".switch").attr 'class', 'switch'
                $("#enable-disable-label").text "Disabled"
            if request.message is "enableInspection"
                $(".switch").attr 'class', 'switch switchOn'
                $("#enable-disable-label").text "Enabled"
    sendRequest
        message: "appStatus"

    #TODO: make hooks to enable/disable

    $(".switch").on 'click', ()->
        $(@).toggleClass "switchOn"
        $("#enable-disable-label").text if $(@).hasClass("switchOn") then "Enabled" else "Disabled"
        sendRequest
            message: "#{if $(@).hasClass("switchOn") then "enable" else "disable"}Inspection"