query_url = 'http://www.xiami.com/ajax/search-index?key='

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1'

playlist = []

formatString = (name_string) ->
  # 1. to lower case.
  # 2. remove \".
  # 3. replace .& note with space.
  # 4. remove [Vinyl] somethin at last.
  # 5. if have 2 spaces in a row, replace it with one.
  # 6. if first or last one is a space, remove it.
  return name_string.toLowerCase().replace(/\"/g, '').replace(/[\-\|&@#。·.:,/]/g, " ").replace(/\s{1,3}(\[.+\]|\(.+\))$/, "").replace(/[\s]{2,}/g, ' ').replace(/(^\s|\s$)/g, '')

# new method to get album id, 
getAlbumId = (request_album_name, request_performers_in_array, link_tags) ->
  id = ""
  if link_tags.length != 0
    # Chinese traditional to simplified
    request_album_name = simplify request_album_name
    # lowercase, replace " and other puncs
    request_album_name = formatString request_album_name
    console.log "request_album_name: " + request_album_name
    
    request_performers = request_performers_in_array.join(' ')
    request_performers = simplify request_performers
    request_performers = formatString request_performers
    console.log "request_performer: " + request_performers
    
    if link_tags.length == 1
      title = formatString link_tags[0].title
      console.log "title1: " + title
      # just test if xiami's title have the album name from douban
      # maybe we can assert that the only one is the one. (if have no other methods at last.)
      console.log title.indexOf(request_album_name)
      # if title.indexOf(request_album_name) != -1 or request_album_name.indexOf(title) != -1
      id = link_tags[0].href.match(/\/album\/(\d+)/)[1]
    else
      for link in link_tags
        title = link.title
        performer = link.innerText.replace(title, "").replace(/\n/g, '').replace(/^\s*/, '')
        title = formatString title
        performer = simplify performer
        performer = formatString performer
        console.log "performer: " + performer
        console.log "title2: " + title
        console.log "douban performers: " + request_performers
        # match rules:
        # title contains and performer contains mutually
        if (title.indexOf(request_album_name) != -1 or request_album_name.indexOf(title) != -1) && (request_performers.indexOf(performer) != -1 || performer.indexOf(request_performers) != -1)
          id = link.href.match(/\/album\/(\d+)/)[1]
          break
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
    if request.performers.length == 1
      query_item = request.performers + " " + request.album
    else
      query_item = request.album
    # Chinese traditional to simplified
    query_item = simplify query_item
    console.log "orginal query item: " + query_item
    # lowercase, replace " and other puncs
    query_item = formatString query_item
    console.log "orginal query item: " + query_item
    query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+')
    query_item = encodeURIComponent(query_item)
    console.log query_url+query_item
    tab = sender.tab.id
    xhr = new XMLHttpRequest()
    xhr.open "GET", query_url+query_item, true
    xhr.timeout = 5000
    xhr.ontimeout = ->
      console.log "time out 了。"
    xhr.onreadystatechange = ->
      if xhr.readyState == 4
        if xhr.status == 200
          albums = $(xhr.responseText).find('a[class="album_result"]')
          console.log albums[0]
          album = getAlbumId request.album, request.performers, albums
          console.log "album id is: " + album
          if album != ""
            createFrame album, tab
          else
            sendResponse {status: "not found"}
        else
          sendResponse {status: "response timeout"}
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
      
  