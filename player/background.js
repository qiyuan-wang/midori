// Generated by CoffeeScript 1.6.3
var TIMEOUT_DURATION, TIMEOUT_MAX_RETRY_TIME, attempts, createFrame, formatString, getAlbumId, normalizeText, player_url, playlist, query_url, replaceCallback, showPageAction;

query_url = 'http://www.xiami.com/ajax/search-index?key=';

player_url = 'http://www.xiami.com/song/playlist/id/{album_id}/type/1';

playlist = [];

TIMEOUT_MAX_RETRY_TIME = 3;

TIMEOUT_DURATION = 5000;

attempts = 0;

replaceCallback = function(match, p1, p2, p3, offset, string) {
  if (p2.length > 1) {
    return p2;
  } else {
    return match;
  }
};

formatString = function(name_string) {
  return name_string.toLowerCase().replace(/(\()(.+)(\))/g, replaceCallback).replace(/[\"\'\-\|&@#。·.:,/【】]/g, ' ').replace(/[\s]{2,}/g, ' ').replace(/(^\s+|\s+$)/g, '');
};

normalizeText = function(name_string) {
  name_string = simplify(name_string);
  name_string = formatString(name_string);
  return name_string;
};

getAlbumId = function(request_album_name, request_performers_in_array, link_tags) {
  var db_album_alias_name, db_album_main_name, db_request_performers, id, link, performer, title, _i, _len;
  id = "";
  if (link_tags.length === 0) {
    return id;
  }
  db_album_main_name = normalizeText(request_album_name.main);
  if (request_album_name.alias) {
    db_album_alias_name = normalizeText(request_album_name.alias);
  }
  db_request_performers = request_performers_in_array.join(' ');
  db_request_performers = normalizeText(db_request_performers);
  if (link_tags.length === 1) {
    title = formatString(link_tags[0].title);
    id = link_tags[0].href.match(/\/album\/(\d+)/)[1];
  } else {
    for (_i = 0, _len = link_tags.length; _i < _len; _i++) {
      link = link_tags[_i];
      title = link.title;
      performer = link.innerText.replace(title, "").replace(/\n/g, '').replace(/^\s*/, '');
      title = normalizeText(title);
      performer = normalizeText(performer);
      if ((title === db_album_main_name || title === db_album_alias_name || title.indexOf(db_album_main_name) !== -1 || title.indexOf(db_album_alias_name) !== -1) && (db_request_performers.indexOf(performer) !== -1 || performer.indexOf(db_request_performers) !== -1)) {
        id = link.href.match(/\/album\/(\d+)/)[1];
        break;
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
  var $iframe, msg, query_item, sendXHR, tab;
  if (request.type === "query") {
    if (request.performers.length === 1 && request.performers[0] !== request.album.main) {
      query_item = request.performers + " " + request.album.main;
    } else {
      query_item = request.album.main;
    }
    query_item = normalizeText(query_item);
    query_item = encodeURIComponent(query_item);
    tab = sender.tab.id;
    sendXHR = function(query_url) {
      var xhr, xhrCallback, xhrTimeout;
      xhr = new XMLHttpRequest();
      xhr.open("GET", query_url, true);
      xhr.timeout = TIMEOUT_DURATION;
      xhrTimeout = function() {
        if (typeof xhr === 'object') {
          xhr.abort();
        }
        if (attempts < TIMEOUT_MAX_RETRY_TIME) {
          attempts++;
          sendXHR(query_url);
        } else {
          attempts = 0;
          sendResponse({
            status: "response timeout"
          });
        }
      };
      xhrCallback = function() {
        var album, albums;
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {
            albums = $(xhr.responseText).find('a[class="album_result"]');
            album = getAlbumId(request.album, request.performers, albums);
            if (album !== "") {
              createFrame(album, tab);
            } else {
              sendResponse({
                status: "not found"
              });
            }
          }
        }
      };
      xhr.ontimeout = xhrTimeout;
      xhr.onreadystatechange = xhrCallback;
      xhr.send();
    };
    sendXHR(query_url + query_item);
    return true;
  }
  if (request.type === "track search") {
    $iframe = $('iframe');
    tab = parseInt($iframe.get(0).id);
    $iframe.remove();
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
