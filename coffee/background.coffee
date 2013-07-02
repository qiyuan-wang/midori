query_url = 'http://www.xiami.com/ajax/search-index?key='

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1'
album_id = ""

playlist = []

createFrame = (album_id, tab_id) ->
  frame = document.createElement('iframe')
  frame.src = player_url.replace('{album_id}', album_id)
  frame.width = 0
  frame.height = 0
  frame.id = tab_id
  $('#player').append(frame)


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  if request.type == "query"
    # prepare the query words
    query_item = request.performer + " " + request.album
    query_item = simplify query_item.toLowerCase()
    console.log query_item 
    query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+')
    query_item = encodeURIComponent(query_item)
    tab = sender.tab.id
    xhr = new XMLHttpRequest()
    xhr.open "GET", query_url+query_item, true
    xhr.onreadystatechange = ->
      if xhr.readyState == 4
        if xhr.status == 200
          resp = xhr.responseText.match(/\/album\/(\d+)/g)
          console.log "resp "+ resp
          album = RegExp.$1
          console.log "album is" + album
          if resp != "" && album != ""
            createFrame album, tab
          else
            sendResponse {status: "not found"}
        else
          console.log xhr.statusText
          sendResponse {status: "network fail"}
    xhr.send()
    return true
  if request.type == "track search"
    iframe = $('iframe')[0]
    tab = parseInt iframe.id
    $(iframe).remove()
    # iframes.each (index)->
    #   console.log this.id
    #   if this.src.indexOf(request.album_id) != -1
    #     
    #     tab = parseInt(this.id, 10)
    #     $(this).remove()
    if request.status == "ready"
      msg =
        status: "found"
        songs: request.songs
    else if request.status == "not found"
      msg = 
        status: "not found"
    console.log tab, msg
    chrome.tabs.sendMessage tab, msg
        

      
  