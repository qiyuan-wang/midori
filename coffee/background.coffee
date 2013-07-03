query_url = 'http://www.xiami.com/ajax/search-index?key='

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1'

playlist = []

formatAlbumName = (name_string) ->
  return name_string.toLowerCase().replace(/[\"\-\|&@#。·]/g, '').replace(/[\s]{2,}/g, ' ')

# new method to get album id, 
getAlbumId = (request_album_name, link_tags) ->
  id = ""
  if link_tags.length != 0
    # Chinese traditional to simplified
    request_album_name = simplify request_album_name
    # lowercase, replace " and other puncs
    request_album_name = formatAlbumName request_album_name
    console.log "request_album_name: " + request_album_name
    link_tags.each ->
      title = formatAlbumName this.title
      console.log "title: " + title
      if title.indexOf(request_album_name) != -1
        id = this.href.match(/\/album\/(\d+)/)[1]
      return
  return id

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
    console.log "orginal query item: " + query_item
    # Chinese traditional to simplified
    query_item = simplify query_item
    # lowercase, replace " and other puncs
    query_item = formatAlbumName query_item
    console.log query_item 
    query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+')
    query_item = encodeURIComponent(query_item)
    console.log query_url+query_item
    tab = sender.tab.id
    xhr = new XMLHttpRequest()
    xhr.open "GET", query_url+query_item, true
    xhr.onreadystatechange = ->
      if xhr.readyState == 4
        if xhr.status == 200
          albums = $(xhr.responseText).find('a[class="album_result"]')
          console.log albums[0]
          album = getAlbumId request.album, albums
          console.log "album id is: " + album
          if album != ""
            createFrame album, tab
          else
            sendResponse {status: "not found"}
        else
          sendResponse {status: "network fail"}
    xhr.send()
    return true
  if request.type == "track search"
    iframe = $('iframe')[0]
    tab = parseInt iframe.id
    $(iframe).remove()
    if request.status == "ready"
      msg =
        status: "found"
        songs: request.songs
    else if request.status == "not found"
      msg = 
        status: "not found"
    console.log msg
    chrome.tabs.sendMessage tab, msg
        

      
  