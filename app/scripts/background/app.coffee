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
                                # TODO: fill with content:  <<response.data>>
                                chrome.tabs.sendMessage tabId,
                                    message: 'loadTemplate'
                                    name: response.name
                                    csrf: message_bus_uuid
                                    data: html
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
