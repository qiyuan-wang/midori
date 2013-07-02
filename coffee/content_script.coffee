tracklist = total_tracks = current_track = audio = info = title = play_button = duration = play_progress = play_pause = next_song = previous_song =

queryAlbum = ->
  # get the album info(name and performer)
  $album_name = $('#wrapper h1 > span')[0].innerText
  $performer = $('#info span span.pl a')[0].innerText
  that = this
  that.innerText = "连接中"
  query_info =
    type: "query" 
    album: $album_name
    performer: $performer
  chrome.runtime.sendMessage query_info, (response) ->
    if response.status == "not found"
      that.innerText = "虾米貌似目前还没有这张专辑"
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
  play_progress = document.createElement('div')
  play_progress.id = "dx_progress"
  
  duration.appendChild play_progress
  
  info.appendChild title
  info.appendChild audio
  info.appendChild duration
  
  panel = document.createElement('div')
  panel.id = "dx_panel"
  
  play_pause = document.createElement('div')
  play_pause.id = "dx_play_pause"
  play_pause.className = "dx_icon"
  
  
  next_song = document.createElement('div')
  next_song.id = "dx_next"
  next_song.className = "dx_icon"
  
  previous_song = document.createElement('div')
  previous_song.id = "dx_prev"
  previous_song.className = "dx_icon"
  
  
  panel.appendChild play_pause
  panel.appendChild next_song 
  panel.appendChild previous_song
  
  player.appendChild panel
  player.appendChild info
  play_section.appendChild player
  return

initPlayer = (song_list)->
  tracklist = song_list
  total_tracks = tracklist.length
  current_track = 0
  

loadTrack = (track_number) ->
  track = tracklist[track_number]
  audio.src = track.location
  title.innerText = track.artist + " - " + track.title
  audio.autoplay = true
  audio.addEventListener "ended", nextTrack, false
  audio.addEventListener "timeupdate", updateProgress, false

nextTrack = ->
  setProgress 0
  current_track++
  if current_track >= total_tracks
    current_track = 0
  loadTrack current_track

previousTrack = ->
  setProgress 0
  current_track--
  if current_track <= -1
    current_track = total_tracks - 1
  loadTrack current_track

updateProgress = ->
  width = parseInt $(duration).css('width')
  percent_played = audio.currentTime / audio.duration
  bar_width = Math.ceil(percent_played * width)
  setProgress bar_width

toggleMusic = ->
  if audio.paused
    audio.play()
    play_pause.innerText = "pause"
  else
    audio.pause()
    play_pause.innerText = "play"

setProgress = (played_length) ->
  $(play_progress).css('width', played_length)

  
bindButtonsEvents = ->
  play_pause.addEventListener "click", toggleMusic, false
  next_song.addEventListener "click", nextTrack, false  
  previous_song.addEventListener "click", previousTrack, false

removeTryButton = ->
  $('#dx_try_button').remove()
  
# insert the play section
play_section = document.createElement('div')
play_section.id = "dx_section"

try_button = document.createElement('a')
try_button.id = "dx_try_button"
try_button.innerText = "虾米试听"

play_section.appendChild(try_button)

# add to page
$('.related_info').before(play_section)

#add click event
$('#dx_try_button').on "click", queryAlbum


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  if request.status == "found"
    removeTryButton()
    createPlayerDOM()
    initPlayer request.songs
    loadTrack current_track
    bindButtonsEvents()
  else if request.status == "not found"
     $('#dx_try_button').innerText = "虾米貌似还没有人发布这张专辑"
  return