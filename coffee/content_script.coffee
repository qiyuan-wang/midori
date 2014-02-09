tracklist = total_tracks = current_track = audio = info = title = play_button = duration = load_progress = play_progress = play_pause = next_song = previous_song = increase_vol = decrease_vol = switch_loop = 0

default_volume = 0.7

single_loop = false

is_playing = true

getPerformers = ->
  performers = []
  $elements = $('#info > span > span.pl').filter( -> return $(this).text().match(/表演者/))
  if $elements.length is 0
    return performers
  $performers = $elements.children()
  $performers.each ->
    performers.push this.innerText # remove any 'soundtrack' and 'various artists' and last space
                        .replace(/(original\s)?(motion picture\s)?soundtrack/i, "")
                        .replace(/various\s?artist(s)?/i, "")
                        .replace(/(^\s+|\s+$)/g, '')
  performers

getAlbumName = ->
  album_name = {}
  name = $('#wrapper h1 > span')[0].innerText
  
  # 1. remove '[7"vinyl]' kind of things.
  # 2. trim space at the begining and end.
  album_name.main = name.replace(/(\(|\[)[^\s]*\s?vinyl(\]|\))/ig, '')
                   .replace(/(^\s+|\s+$)/g, '')
                   
  # if it has an alias name:
  if $('#info > span.pl').filter( -> return $(this).text().match(/又名/))
    # the alias name text is the 3rd text content
    alias = $('#info br').parent().contents()[2].textContent
    album_name.alias = alias.replace(/(\(|\[)[^\s]*\s?vinyl(\]|\))/ig, '')
                     .replace(/(^\s+|\s+$)/g, '')
  album_name
  # remove previous regexp
  #.replace(/(:\s)?(music from the\s)?([\(\[])?(original\s)?(motion picture\s)?((soundtrack)|(score))([\)\[])?/i, "")#.replace(/\s*((lp)|(ep))$/i, "")

queryAlbum = ->
  # get the album info(name and performers)
  $album_name = getAlbumName() # it's a object
  $performers = getPerformers() # it's a array
  
  # remove the midori icon
  $(this).remove()
  
  # update the tips text
  tips.innerText = "翻虾米找专辑中"
  
  # console.log "douban_performers: " + $performers
  # console.log "douban_album: " + $album_name.main
  
  if $album_name.alias
    console.log "douban_alias: " + $album_name.alias
  
  query_info =
    type: "query" 
    album: $album_name
    performers: $performers
  
  chrome.runtime.sendMessage query_info, (response) ->
    switch response.status
      when "not found"
        $(tips).text("虾米上貌似目前还没有这张专辑。")
        .removeClass("dx_notice").addClass("dx_warning")
      when "response timeout"     
        $(tips).text("虾米网络不给力啊，重试了三次都不返回结果，等会儿吧。")
        .removeClass("dx_notice").addClass("dx_warning")
      else
    return
  return

createPlayerDOM = ->
  player = document.createElement('div')
  player.id = "dx_player"
  
  info = document.createElement('div')
  info.id = "dx_info"
  
  title = document.createElement('div')
  title.id = "dx_title"
  
  audio = document.createElement('audio')
  
  duration = document.createElement('div')
  duration.id = "dx_duration"
  
  load_progress = document.createElement('div')
  load_progress.id = "dx_load_progress"
  
  play_progress = document.createElement('div')
  play_progress.id = "dx_progress"
  
  load_progress.appendChild play_progress
  
  duration.appendChild load_progress
  
  info.appendChild title
  info.appendChild audio
  info.appendChild duration
  
  panel = document.createElement('div')
  panel.id = "dx_panel"
  
  play_pause = document.createElement('div')
  play_pause.id = "dx_play_pause"
  play_pause.className = "dx_icon dx_pause"
  
  next_song = document.createElement('div')
  next_song.id = "dx_next"
  next_song.className = "dx_icon"
  
  previous_song = document.createElement('div')
  previous_song.id = "dx_prev"
  previous_song.className = "dx_icon"
  
  increase_vol = document.createElement('div')
  increase_vol.id = "dx_inc_vol"
  increase_vol.className = "dx_icon"
  
  decrease_vol = document.createElement('div')
  decrease_vol.id = "dx_dec_vol"
  decrease_vol.className = "dx_icon"
    
  switch_loop = document.createElement('div')
  switch_loop.className = "dx_normal dx_icon"
  
  panel.appendChild play_pause
  panel.appendChild next_song 
  panel.appendChild previous_song
  panel.appendChild increase_vol
  panel.appendChild decrease_vol
  panel.appendChild switch_loop
  
  player.appendChild panel
  player.appendChild info
  play_section.appendChild player
  return

initPlayer = (song_list)->
  tracklist = song_list
  total_tracks = tracklist.length
  current_track = 0
  return

loadTrack = (track_number) ->
  track = tracklist[track_number]
  audio.src = track.location
  title.innerText = track.artist + " - " + track.title
  audio.volume = default_volume
  audio.addEventListener "ended", nextTrackAuto, false
  audio.addEventListener "timeupdate", updateProgress, false
  audio.addEventListener "progress", updateLoadProgress, false
  if is_playing == true
    audio.play()
  return


nextTrack = ->
  setProgress 0
  current_track++
  if current_track >= total_tracks
    current_track = 0
  loadTrack current_track
  return

nextTrackAuto = ->
  setProgress 0
  if single_loop
    audio.play()
  else
    nextTrack()
  return

previousTrack = ->
  setProgress 0
  current_track--
  if current_track <= -1
    current_track = total_tracks - 1
  loadTrack current_track
  return

increaseVolume = ->
  default_volume += 0.1
  if default_volume > 1.0
    default_volume = 1.0
  audio.volume = default_volume
  return
  
decreaseVolume = ->
  default_volume -= 0.1
  if default_volume < 0.09
    default_volume = 0.0
  audio.volume = default_volume
  return

updateLoadProgress = ->
  if audio.buffered != undefined && audio.buffered.length != 0
    width = parseInt $(duration).css('width')
    percent_loaded = audio.buffered.end(0) / audio.duration
    bar_width = Math.ceil(percent_loaded * width)
    $(load_progress).css('width', bar_width)
  return

updateProgress = ->
  width = parseInt $(duration).css('width')
  percent_played = audio.currentTime / audio.duration
  bar_width = Math.ceil(percent_played * width)
  setProgress bar_width
  return

toggleMusic = ->
  if is_playing == false
    audio.play()
    $(play_pause).removeClass('dx_play')
    $(play_pause).addClass('dx_pause')
  else
    audio.pause()
    $(play_pause).removeClass('dx_pause')
    $(play_pause).addClass('dx_play')
  is_playing = !is_playing 
  return
  
  
switchLoop = ->
  if single_loop
    single_loop = false
    $(switch_loop).removeClass("dx_loop").addClass("dx_normal")
  else
    single_loop = true
    $(switch_loop).removeClass("dx_normal").addClass("dx_loop")

setProgress = (played_length) ->
  $(play_progress).css('width', played_length)
  return


bindButtonsEvents = ->
  play_pause.addEventListener "click", toggleMusic, false
  next_song.addEventListener "click", nextTrack, false  
  previous_song.addEventListener "click", previousTrack, false
  increase_vol.addEventListener "click", increaseVolume, false
  decrease_vol.addEventListener "click", decreaseVolume, false
  switch_loop.addEventListener "click", switchLoop, false

removeTips = ->
  $(tips).remove()

# try keyboard binding

# for key m
startMidori = ->
  if $('#dx_try_button')
    $('#dx_try_button').trigger('click')
  return

bindKeyboardEvents = ->
  $(document).keypress (evt) ->
    switch evt.which
      when 32 # space bar
        evt.preventDefault() #prevent page rolling down
        toggleMusic()
      when 110 then nextTrack() # key n
      when 112 then previousTrack() # key p
      when 61 then increaseVolume() # key =
      when 45 then decreaseVolume() # key -
      when 108 then switchLoop() # key l
      else
    return
       
# insert the play section
play_section = document.createElement('div')
play_section.id = "dx_section"

try_button = document.createElement('div')
try_button.id = "dx_try_button"

tips = document.createElement('span')
tips.id = "tips"
tips.className = "dx_notice"

play_section.appendChild try_button
play_section.appendChild tips

# add to page
$('.related_info').before(play_section)

#add click event
$('#dx_try_button').on "click", queryAlbum

$(document).keypress (evt) ->
  if evt.which is 109 # key m
    startMidori()
  return

# stop event propagation to avoid keyboard shortcuts if focusing on search input element.
$('#inp-query').bind "keypress", (evt) ->
  evt.stopPropagation()
  return
  

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  if request.status is "found"
    removeTips()
    createPlayerDOM()
    initPlayer request.songs
    loadTrack current_track
    bindButtonsEvents()
    bindKeyboardEvents()
  else if request.status is "not found"
    $(tips).text("虾米上貌似还没有人发布这张专辑。").removeClass("dx_notice").addClass("dx_warning")
  return