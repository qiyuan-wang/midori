// Generated by CoffeeScript 1.6.3
var createFrame, formatAlbumName, getAlbumId, player_url, playlist, query_url, showPageAction;

query_url = 'http://www.xiami.com/ajax/search-index?key=';

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1';

playlist = [];

formatAlbumName = function(name_string) {
  return name_string.toLowerCase().replace(/\"|/g, '').replace(/[\-\|&@#。·.:,]/g, " ").replace(/\s{0,3}(\[.+\]|\(.+\))$/, "").replace(/[\s]{2,}/g, ' ').replace(/(^\s|\s$)/g, '');
};

getAlbumId = function(request_album_name, link_tags) {
  var id, link, title, _i, _len;
  id = "";
  if (link_tags.length !== 0) {
    request_album_name = simplify(request_album_name);
    request_album_name = formatAlbumName(request_album_name);
    console.log("request_album_name: " + request_album_name);
    if (link_tags.length === 1) {
      title = formatAlbumName(link_tags[0].title);
      console.log("title1: " + title);
      console.log(title.indexOf(request_album_name));
      if (title.indexOf(request_album_name) !== -1 || request_album_name.indexOf(title) !== -1) {
        id = link_tags[0].href.match(/\/album\/(\d+)/)[1];
      }
    } else {
      for (_i = 0, _len = link_tags.length; _i < _len; _i++) {
        link = link_tags[_i];
        title = formatAlbumName(link.title);
        console.log("title2: " + title);
        if (title === request_album_name) {
          id = link.href.match(/\/album\/(\d+)/)[1];
          break;
        }
      }
    }
  }
  return id;
};

createFrame = function(album_id, tab_id) {
  var frame;
  frame = document.createElement('iframe');
  frame.src = player_url.replace('{album_id}', album_id);
  frame.width = 0;
  frame.height = 0;
  frame.id = tab_id;
  return $('#player').append(frame);
};

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  var iframe, msg, query_item, tab, xhr;
  if (request.type === "query") {
    query_item = request.performer + " " + request.album;
    console.log("orginal query item: " + query_item);
    query_item = simplify(query_item);
    query_item = formatAlbumName(query_item);
    query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+');
    query_item = encodeURIComponent(query_item);
    console.log(query_url + query_item);
    tab = sender.tab.id;
    xhr = new XMLHttpRequest();
    xhr.open("GET", query_url + query_item, true);
    xhr.onreadystatechange = function() {
      var album, albums;
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          albums = $(xhr.responseText).find('a[class="album_result"]');
          console.log(albums[0]);
          album = getAlbumId(request.album, albums);
          console.log("album id is: " + album);
          if (album !== "") {
            return createFrame(album, tab);
          } else {
            return sendResponse({
              status: "not found"
            });
          }
        } else {
          return sendResponse({
            status: "network fail"
          });
        }
      }
    };
    xhr.send();
    return true;
  }
  if (request.type === "track search") {
    iframe = $('iframe')[0];
    tab = parseInt(iframe.id);
    $(iframe).remove();
    if (request.status === "ready") {
      msg = {
        status: "found",
        songs: request.songs
      };
    } else if (request.status === "not found") {
      msg = {
        status: "not found"
      };
    }
    chrome.tabs.sendMessage(tab, msg);
    return true;
  }
});

showPageAction = function(tabId, changeInfo, tab) {
  if (tab.url.indexOf('music.douban.com\/subject\/') !== -1) {
    chrome.pageAction.show(tabId);
  }
};

chrome.tabs.onUpdated.addListener(showPageAction);
