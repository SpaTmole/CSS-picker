chrome.runtime.onInstalled.addListener ()->
    chrome.contextMenus.create({type: "separator", contexts: ["all"]}, ()->
        chrome.contextMenus.create({
            title: "Inspect element style",
            id: "contextMenuInspectorItem",
            contexts: ["all"]
        }, ()->
            chrome.contextMenus.create({type: "separator", contexts: ["all"]})
        )
        chrome.contextMenus.onClicked.addListener((info, tab) ->
            if(info.menuItemId == "contextMenuInspectorItem")
                console.log('Inspecting element: ', arguments)
                chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
                    chrome.tabs.sendMessage tabs[0].id,
                        {
                            data: 'contextMenu'
                            csrf: '1' # TODO: of course it is insecure, use uuid with sha
                        },
                        (response) ->
                            console.log(response)
            return
        )
    )
