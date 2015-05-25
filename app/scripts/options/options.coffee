$(document).ready ()->
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    port = chrome.runtime.connect name: message_bus_uuid
    shortcut = ""
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
                shortcut = request.advanced.hotkey
                $("#ext-shortcut-keeper #shortcut_setup").val(shortcut);
            if request.message is "disableInspection"
                $(".switch").attr 'class', 'switch'
                $("#enable-disable-label").text "Disabled"
            if request.message is "enableInspection"
                $(".switch").attr 'class', 'switch switchOn'
                $("#enable-disable-label").text "Enabled"
    sendRequest
        message: "appStatus"

    $(".switch").on 'click', ()->
        $(@).toggleClass "switchOn"
        $("#enable-disable-label").text if $(@).hasClass("switchOn") then "Enabled" else "Disabled"
        sendRequest
            message: "#{if $(@).hasClass("switchOn") then "enable" else "disable"}Inspection"

    $("#ext-shortcut-toggler").on 'click', ()->
        $("#ext-shortcut-keeper").toggle "slide", {direction: "left"}

    $("#ext-shortcut-keeper #shortcut_setup").on('focus', ()->
        ((self)->
            $(self).val("Press key sequence...")
            Mousetrap.record (sequence) ->
                # sequence is an array like ['ctrl+k', 'c']
                if sequence.length
                    shortcut = sequence[sequence.length - 1]
                $(self).val shortcut
                $(self).blur()
                sendRequest
                    message: "setupShortcut"
                    data: shortcut
        )(@)


    ).on('blur', ()->
        $(@).val(shortcut)
    ).val(shortcut)

    $('#drop').on('click', ()->
        $("#ext-shortcut-keeper #shortcut_setup").val("");
        shortcut = ''
        sendRequest
            message: "setupShortcut"
            data: shortcut
    )