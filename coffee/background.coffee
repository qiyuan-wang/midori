query_url = 'http://www.xiami.com/ajax/search-index?key='

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1'

playlist = []

formatAlbumName = (name_string) ->
  # 1. to lower case.
  # 2. remove "".
  # 3. replace .& note with space.
  # 4. remove [Vinyl] somethin at last.
  # 5. if have 2 spaces in a row, replace it with one.
  # 6. if last one is a space, remove it.
  return name_string.toLowerCase().replace(/\"|/g, '').replace(/[\-\|&@#。·.:]/g, " ").replace(/\s{0,3}(\[.+\]|\(.+\))$/, "").replace(/[\s]{2,}/g, ' ').replace(/\s$/g, '')

# new method to get album id, 
getAlbumId = (request_album_name, link_tags) ->
  id = ""
  if link_tags.length != 0
    # Chinese traditional to simplified
    request_album_name = simplify request_album_name
    # lowercase, replace " and other puncs
    request_album_name = formatAlbumName request_album_name
    console.log "request_album_name: " + request_album_name
    
    if link_tags.length == 1
      title = formatAlbumName link_tags[0].title
      console.log "title1: " + title
      # just include
      # maybe we can assert that the only one is the one. (if have no other methods at last.)
      console.log title.indexOf(request_album_name)
      if title.indexOf(request_album_name) != -1 or request_album_name.indexOf(title) != -1
        id = link_tags[0].href.match(/\/album\/(\d+)/)[1]
    else
      link_tags.each ->
        title = formatAlbumName this.title
        console.log "title2: " + title
        # more strict on comparision: must equal
        if title == request_album_name    
          id = this.href.match(/\/album\/(\d+)/)[1]
          # console.log id
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
    # console.log msg
    chrome.tabs.sendMessage tab, msg
    return true


# show the page action icon only on music.douban.com/subject/ pages
showPageAction = (tabId, changeInfo, tab)->
  if tab.url.indexOf('music.douban.com\/subject\/') != -1
    chrome.pageAction.show(tabId)
  return

chrome.tabs.onUpdated.addListener(showPageAction)
      
  