/**
 * Created by konstantin on 1/25/15.
 */
(function(){
   chrome.contextMenus.create({
        type: "separator"
   }, function(){
       chrome.contextMenus.create({
           type: "normal",
           title: "Inspect element style ",
           id: "contextMenuInspectorItem"
       }, function(){chrome.contextMenus.create({
        type: "separator"})});
   });
})();