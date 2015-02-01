$(document).ready ()->
    $(window).on('mousedown', (e)->
        if e.button is 2
            window.custom_selected_element = $(e.toElement)
    )

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    if request.csrf == '1' # TODO: of course it is insecure, use uuid with sha
        console.log 'Data Recieved: ', request.data, window.custom_selected_element
