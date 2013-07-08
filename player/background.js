// Generated by CoffeeScript 1.6.3
var createFrame, formatString, getAlbumId, player_url, playlist, query_url, showPageAction;

query_url = 'http://www.xiami.com/ajax/search-index?key=';

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1';

playlist = [];

formatString = function(name_string) {
  return name_string.toLowerCase().replace(/\"/g, '').replace(/[\-\|&@#。·.:,]/g, " ").replace(/\s{0,3}(\[.+\]|\(.+\))$/, "").replace(/[\s]{2,}/g, ' ').replace(/(^\s|\s$)/g, '');
};

getAlbumId = function(request_album_name, request_performers_in_array, link_tags) {
  var id, link, performer, request_performers, title, _i, _len;
  id = "";
  if (link_tags.length !== 0) {
    request_album_name = simplify(request_album_name);
    request_album_name = formatString(request_album_name);
    console.log("request_album_name: " + request_album_name);
    request_performers = request_performers_in_array.join(' ');
    request_performers = simplify(request_performers);
    request_performers = formatString(request_performers);
    console.log("request_performer: " + request_performers);
    if (link_tags.length === 1) {
      title = formatString(link_tags[0].title);
      console.log("title1: " + title);
      console.log(title.indexOf(request_album_name));
      if (title.indexOf(request_album_name) !== -1 || request_album_name.indexOf(title) !== -1) {
        id = link_tags[0].href.match(/\/album\/(\d+)/)[1];
      }
    } else {
      for (_i = 0, _len = link_tags.length; _i < _len; _i++) {
        link = link_tags[_i];
        title = link.title;
        performer = link.innerText.replace(title, "").replace(/\n/g, '').replace(/^\s*/, '');
        title = formatString(title);
        performer = formatString(performer);
        console.log("performer: " + performer);
        console.log("title2: " + title);
        console.log("douban performers: " + request_performers);
        if (title === request_album_name && request_performers.indexOf(performer) !== -1) {
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
    if (request.performers.length === 1) {
      query_item = request.performers + " " + request.album;
    } else {
      query_item = request.album;
    }
    query_item = simplify(query_item);
    query_item = formatString(query_item);
    console.log("orginal query item: " + query_item);
    query_item = query_item.replace(/\s/g, '+').replace(/[+]{2,}/g, '+');
    query_item = encodeURIComponent(query_item);
    console.log(query_url + query_item);
    tab = sender.tab.id;
    xhr = new XMLHttpRequest();
    xhr.open("GET", query_url + query_item, true);
    xhr.timeout = 5000;
    xhr.ontimeout = function() {
      return console.log("time out 了。");
    };
    xhr.onreadystatechange = function() {
      var album, albums;
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          albums = $(xhr.responseText).find('a[class="album_result"]');
          console.log(albums[0]);
          album = getAlbumId(request.album, request.performers, albums);
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
            status: "response timeout"
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
