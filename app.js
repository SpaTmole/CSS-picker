/**
 * Created by konstantin on 1/25/15.
 */
chrome.runtime.onInstalled.addListener(function(){
   chrome.contextMenus.create({type: "separator", contexts: ["all"]}, function(){
       chrome.contextMenus.create({
           title: "Inspect element style",
           id: "contextMenuInspectorItem",
           contexts: ["all"]
       }, function(){chrome.contextMenus.create({type: "separator", contexts: ["all"]})});
       chrome.contextMenus.onClicked.addListener(function (info, tab) {
           if(info.menuItemId == "contextMenuInspectorItem")
               console.log('Inspecting element: ', arguments);
       });
   });
});