chrome.runtime.onInstalled.addListener ()->
    message_bus_uuid = '2151ada6-a6eb-447c-82b9-0b3f30d0aff4'
    chrome.contextMenus.create({type: "separator", contexts: ["all"]}, ()->
        chrome.contextMenus.create({
            title: "Inspect element style",
            id: "contextMenuInspectorItem",
            contexts: ["all"]
        }, ()->
            chrome.contextMenus.create({type: "separator", contexts: ["all"]})
        )
        chrome.contextMenus.onClicked.addListener (info, tab) ->
            if info.menuItemId == "contextMenuInspectorItem"
                console.log 'Inspecting element: ', arguments
                chrome.tabs.query {active: yes, currentWindow: yes}, (tabs) ->
                    chrome.tabs.sendMessage tabs[0].id,
                        {
                            data: 'contextMenu'
                            csrf: message_bus_uuid
                        },
                        (response) ->
                            console.log response
                            alert 'We got it pal'
            return

    )
