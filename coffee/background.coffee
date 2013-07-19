query_url = 'http://www.xiami.com/ajax/search-index?key='

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1'

playlist = []

# for xhr resend quest
TIMEOUT_MAX_RETRY_TIME = 3
TIMEOUT_DURATION = 5000
attempts = 0

replaceCallback = (match, p1, p2, p3, offset, string) ->
  if p2.length > 1
    return p2
  else
    return match

formatString = (name_string) ->
  # 1. to lower case.
  # 2. replace .& note with space.
  # 3. if have 2 spaces in a row, replace it with one.
  # 4. if first or last one is a space, remove it.
  return name_string.toLowerCase()
         .replace(/(\()(.+)(\))/g, replaceCallback)
         .replace(/[\"\'\-\|&@#。·.:,/]/g, ' ')
         .replace(/[\s]{2,}/g, ' ')
         .replace(/(^\s+|\s+$)/g, '')

normalizeText = (name_string) ->
  name_string = simplify name_string
  name_string = formatString name_string
  name_string

# new method to get album id, 
getAlbumId = (request_album_name, request_performers_in_array, link_tags) ->
  id = ""
  if link_tags.length is 0
    return id
  
  # get the query words
  db_album_main_name = normalizeText request_album_name.main
  db_album_alias_name = normalizeText request_album_name.alias if request_album_name.alias

  # console.log "request_album_main_name: " + db_album_main_name
  # console.log "request_album_alias_name: " + db_album_alias_name if db_album_alias_name
  
  db_request_performers = request_performers_in_array.join(' ')
  db_request_performers = normalizeText db_request_performers
  # console.log "request_performer: " + db_request_performers
    
  if link_tags.length == 1
    title = formatString link_tags[0].title
    # console.log "title1: " + title
    
    # just test if xiami's title have the album name from douban
    # maybe we can assert that the only one is the one. (if have no other methods at last.)
    
    # console.log title.indexOf(db_album_main_name)
    
    # if title.indexOf(request_album_name) != -1 or request_album_name.indexOf(title) != -1
    id = link_tags[0].href.match(/\/album\/(\d+)/)[1]
  else
    for link in link_tags
      title = link.title
      performer = link.innerText.replace(title, "").replace(/\n/g, '').replace(/^\s*/, '')
      
      title = normalizeText title
      performer = normalizeText performer
      
      # console.log "performer: " + performer
 #      console.log "title2: " + title
 #      console.log db_album_main_name
 #      console.log title.indexOf(db_album_main_name)
      
      # match rules:
      # 1. title equals main_name or alias_name
      # 2. or title contains main_name or alias_name
      # 3. and perfomers contains.
      if (title is db_album_main_name || title is db_album_alias_name || title.indexOf(db_album_main_name) isnt -1 || title.indexOf(db_album_alias_name) isnt -1) && (db_request_performers.indexOf(performer) isnt -1 || performer.indexOf(db_request_performers) isnt -1)
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
    if request.performers.length is 1
      query_item = request.performers + " " + request.album.main
      console.log "query1: " + query_item 
    else
      query_item = request.album.main
      console.log "query1: " + query_item 

    query_item = normalizeText query_item
    # console.log "orginal query item: " + query_item
    
    # query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+')
    
    query_item = encodeURIComponent query_item
    # console.log query_url+query_item
    
    tab = sender.tab.id
    
    # deal with the xhr
    sendXHR = (query_url) ->
      xhr = new XMLHttpRequest()
      xhr.open "GET", query_url, true
      xhr.timeout = TIMEOUT_DURATION
      
      # define timeout callback
      xhrTimeout = ->
        if typeof xhr is 'object'
          xhr.abort()
        if attempts < TIMEOUT_MAX_RETRY_TIME
          # console.log attempts
          attempts++
          # resend another request
          sendXHR query_url
        else
          attempts = 0
          sendResponse {status: "response timeout"}
        return
      
      # define readystatechange callback
      xhrCallback = ->
        if xhr.readyState is 4
          if xhr.status is 200
            albums = $(xhr.responseText).find('a[class="album_result"]')
            # console.log albums[0]
            
            album = getAlbumId request.album, request.performers, albums
            # console.log "album id is: " + album
            
            if album != ""
              createFrame album, tab
            else
              sendResponse {status: "not found"}
        return
      
      # set timeout and statechange callback
      xhr.ontimeout = xhrTimeout
      xhr.onreadystatechange = xhrCallback
      xhr.send()
      return

    sendXHR query_url+query_item
    return true


  if request.type == "track search"
    $iframe = $('iframe')
    tab = parseInt $iframe.get(0).id
    $iframe.remove()
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
      
  