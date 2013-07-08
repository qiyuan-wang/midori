# decode function
# retrieval location of mp3 from flash
# from isombyt contact:http://isombyt.me
decode = (source) ->
  _loc9 = Number source.charAt(0)
  _loc7 = source.substring(1)
  _loc5 = Math.floor(_loc7.length / _loc9)
  _loc6 = _loc7.length % _loc9
  _loc2 = new Array()
  
  for _loc3 in [0..._loc6] by 1
    if _loc2[_loc3] == undefined
      _loc2[_loc3] = ""
    _loc2[_loc3] = _loc7.substr((_loc5 + 1) * _loc3, _loc5 + 1)
  
  for _loc3 in [_loc6..._loc9] by 1
    _loc2[_loc3] = _loc7.substr(_loc5 * (_loc3 - _loc6) + (_loc5 + 1) * _loc6, _loc5)
  
  _loc4 = ""
  for _loc3 in [0..._loc2[0].length] by 1
    for _loc1 in [0..._loc2.length] by 1
      _loc4 = _loc4 + _loc2[_loc1].charAt(_loc3)
  
  _loc4 = unescape(_loc4)
  _loc8 = ""
  for _loc3 in [0..._loc4.length] by 1
    if _loc4.charAt(_loc3) == "^"
      _loc8 = _loc8 + "0"
      continue
    _loc8 = _loc8 + _loc4.charAt(_loc3)
  return _loc8

playlist = {}
tracks = $('track')
if tracks.length != 0
  songs = []
  tracks.each ->
    track = $(this)
    track_info =
      title: track.find('title').text(),
      artist: track.find('artist').text(),
      album: track.find('album_name').text(),
      location: decode(track.find('location').text())
    # console.log track_info.location
    songs.push track_info
  playlist =
    type: "track search"
    status: "ready"
    album_id: $('playlist').find('type_id').text()
    songs: songs
else
  playlist =
    type: "track search"
    status: "not found"
chrome.runtime.sendMessage playlist

