'use strict';
// todo
// 
// fix retx timeout in websocket_client.on('connectFailed', function(error) {
// we can set IP, but that is removed when clientconnection is nulled on fail
// 
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
// this file is the main file - it contains all the functionality necessary
// to control the TV. A normal user does not need to delve deeper into
// the other files, normally.
// 
// Instantiate the class, and use it.
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
// 
// LG webos smart TV control app
// references:
//    https://github.com/ConnectSDK/Connect-SDK-Android-Core
//    https://github.com/CODeRUS/harbour-lgremote-webos
// 
// 1: send handshake per below -> receive client key if not already
// 2: the protocol is using JSON strings with requests from the client, responses
//    from the TV. Subscriptions probably means the TV will push notifications 
//    without prior individual requests.
// 3: client request has these fields:
//        type : register/request/subscribe
//        id   : command + _ + message count (the response will mirror this number)
//        uri  : command endpoint URI
//        payload  : optional, eg input source string when changing input
// 
// All callbacks follow the common pattern of function(error, ....) {}
// ie first argument is false if the call went ok, or true if an error occurred.
// Then, the second argument is most often the result if applicable, or not
// existant respectively.
// -----------------------------------------------------------------------------
// communication
let comms = require('./lgtv-connection.js');

// discovery mechanism, over SSDP
let discovery = require('./lgtv-discovery.js');

let WebSocketClient = require('websocket').client;

// for matching ws request -- response
let eventemitter = new (require('events').EventEmitter);

// enable infinite number of listeners
eventemitter.setMaxListeners(0);
/*---------------------------------------------------------------------------*/
let dt_log = function(logz) {
  let dt = new Date();
  console.log(dt.toISOString(), logz);
}
console.dt_log = dt_log;
// ---------------------------------------------------------
// unsubscribe from topic
let unsubscribe = function(id, fn) {
  let msg = `{"id":"${id}","type":"unsubscribe"}`
  // console.dt_log("LGTV Unsubscribing:" + msg);

  try {
    if (typeof fn === 'function') {
      eventemitter.once(prefix + command_count, function (message) {
        // console.dt_log("LGTV *** emitter listener for " + prefix + command_count + " with message:" + message); 
        fn(false, message);
      });
    }
    this.conn.ws_send(msg);

  } catch(err) {
    // console.dt_log("LGTV Error, not connected to TV.");
    if (typeof fn === 'function') {
      fn(true, "not connected");
    }
  }
};
// ---------------------------------------------------------
// show a float on the TV
function show_float(text, fn) {
  console.dt_log("LGTV show float, " + text);
  this.conn.send_command("", "request", "ssap://system.notifications/createToast", '{"message": "MSG"}'.replace('MSG', text), fn);
}
// ---------------------------------------------------------
// launch browser at URL; will open a new tab if already open
function open_browser_at(url, fn) {
  // response: {"type":"response","id":"0","payload":{"returnValue":true,"id":"com.webos.app.browser","sessionId":"Y29tLndlYm9zLmFwcC5icm93c2VyOnVuZGVmaW5lZA=="}}

  // must start with http:// or https://
  // console.dt_log('LGTV opening browser at:%s', url);
  let protocol = url.substring(0, 7).toLowerCase();
  if (protocol !== 'http://' && protocol !== 'https:/') {
    url = "http://" + url;
  }

  this.conn.send_command("", "request", "ssap://system.launcher/open", JSON.stringify({target: url}), function(err, resp){
    var ret = "";
    if (!err) {
      ret = {sessionId: resp.payload.sessionId};
    } else {
      ret = JSON.stringify(response);
    }
    fn(err, ret);
  });
}
/*---------------------------------------------------------------------------*/
let turn_off = function(fn) {
  console.dt_log("LGTV turning off");
  this.conn.send_command("", "request", "ssap://system/turnOff", null, fn);
  // XXXXX should here also run close on the connection so that all timers are removed
  // at least if we return with no error
};
/*---------------------------------------------------------------------------*/
let channellist = function(fn) {
  this.conn.send_command("channels_", "request", "ssap://tv/getChannelList", null, function(err, resp) {
  // this.conn.send_command("channels_", "subscribe", "ssap://tv/getChannelList", null, function(err, resp) {
    if (!err) {
      try {
        // extract channel list
        let channellistarray = resp.payload.channelList;
        let retlist = {channels : []};
        for (let i = channellistarray.length - 1; i >= 0; i--) {
          let ch = {id: channellistarray[i].channelId,
                    name: channellistarray[i].channelName,
                    number: channellistarray[i].channelNumber};
          // console.dt_log(channellistarray[i]);
          console.dt_log(ch);
          retlist.channels.push(ch);
        }
        fn(false, JSON.stringify(retlist));
      
      } catch(e) {
        console.dt_log("LGTV extracting channellist Error:" + e);
        fn(true, resp);
      }
    
    } else {
      console.dt_log("LGTV get channellist Error:" + err);
      fn(true, err);
    }
  });
};
/*---------------------------------------------------------------------------*/
// get current channel
let channel = function(fn) {
  // this.conn.send_command("channels_", "subscribe", "ssap://tv/getCurrentChannel", null, function(err, resp) {
  this.conn.send_command("channels_", "request", "ssap://tv/getCurrentChannel", null, function(err, resp) {
// {"type":"response","id":"channels_1","payload": {"channelId":"0_13_7_0_0_1307_0","signalChannelId":"0_1307_0","channelModeId":0,"channelModeName":"Terrestrial","channelTypeId":0,"channelTypeName":"Terrestrial Analog TV","channelNumber":"7","channelName":"SVT  ","physicalNumber":13,"isSkipped":false,"isLocked":false,"isDescrambled":false,"isScrambled":false,"isFineTuned":false,"isInvisible":false,"favoriteGroup":null,"hybridtvType":null,"dualChannel":{"dualChannelId":null,"dualChannelTypeId":null,"dualChannelTypeName":null,"dualChannelNumber":null},"returnValue":true}}

    if (typeof fn === 'function') {
      if (!err) {
        if (resp.error) {
          fn(true, "Error, probably not TV input right now");
        } else {
          // return a subset of all information
          fn(false, {id: resp.payload.channelId, // internal id, used for setting channel
                         name: resp.payload.channelName, // name as on TV, eg SVT
                         number: resp.payload.channelNumber}); // number on TV
        }
      } else {
        console.dt_log("LGTV Error:" + err);
        fn(true, "Error, could not get answer");
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
/* set the active channel; use channelId as from the channellist, such as eg 0_13_7_0_0_1307_0 */
let set_channel = function(channel, fn) {
  this.conn.send_command("", "request", "ssap://tv/openChannel", JSON.stringify({channelId: channel}), function(err, resp){
    if (err) {
      fn(err, {});
    } else {
      if (resp.type == "response") {
        // {"type":"response","id":"1","payload":{"returnValue":true}}
        fn(false, channel);
      } else if (resp.type == "error") {
        // {"type":"error","id":"1","error":"500 Application error","payload":{"returnValue":false,"errorCode":-1000,"errorText":"invalid channel id"}}
        fn(true, resp.payload.errorText);
      } else {
        fn(true, "unknown error");
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
// get list of input sources; HDMI_1, HDMI_2, SCART_1, etc.
// note: the TV does not consider 'live TV' as part of the external input list.
// that is an "app" to the TV
let inputlist = function(fn) {
  // this.conn.send_command("input_", "subscribe", "ssap://tv/getExternalInputList", null, function(err, resp) {
  this.conn.send_command("input_", "request", "ssap://tv/getExternalInputList", null, function(err, resp) {
    if (typeof fn === 'function') {
// <--- received: {"type":"response","id":"input_1","payload": {"devices":[{"id":"SCART_1","label":"AV1","port":1,"appId":"com.webos.app.externalinput.scart","icon":"http://lgsmarttv.lan:3000/resources/f84946f3119c23cda549bdcf6ad02a89c73f7682/scart.png","modified":false,"autoav":false,"currentTVStatus":"","subList":[],"subCount":0,"connected":false,"favorite":false},{...}, {...}],"returnValue":true}}
      if (!err) {
        try {
          // extract a nice and simple inputlist
          let devs = resp.payload.devices;
          let ret = {};
          for (let i = devs.length - 1; i >= 0; i--) {
            ret[devs[i].id] = devs[i].icon;
          }
          console.dt_log("LGTV list of inputs:");
          console.dt_log(ret);
          
          fn(false, ret);
        } catch(error) {
          console.dt_log("LGTV Error:" + error);
          fn(true, error);
        }
      } else {
        console.dt_log("LGTV Error:" + err);
        fn(true, err);
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
// get current input source
let input = function(fn) {
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
// set input source
let set_input = function(input, fn) {
  console.dt_log("LGTV set input:" + input);
  this.conn.send_command("", "request", "ssap://tv/switchInput", JSON.stringify({inputId: input}), function(err, resp){
    if (err) {
      fn(true, resp);
    } else {
      if (resp.payload.errorCode) {
        fn(true, resp.payload.errorText);
        // {"type":"response","id":"1","payload":{"returnValue":true,"errorCode":-1000,"errorText":"no such input"}}
      } else {
        fn(false, input);
        // {"type":"response","id":"1","payload":{"returnValue":true}}
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
// set mute
let set_mute = function(setmute, fn) {
  console.dt_log("LGTV set mute: " + setmute);
  if(typeof setmute !== 'boolean') {
    fn(true, {reason: "mute must be boolean"});
  } else {
    this.conn.send_command("", "request", "ssap://audio/setMute", JSON.stringify({mute: setmute}), fn);
  }
};
/*---------------------------------------------------------------------------*/
// if muted, then unmute, and vice versa.
// not a native function, so we first get the state of mute
let toggle_mute = function(fn) {
  console.dt_log("LGTV toggle mute");
  muted(function(err, resp){
    if (!err) {
      let tomute = !resp;
      this.conn.send_command("", "request", "ssap://audio/setMute", JSON.stringify({mute: tomute}), fn);
    } else {
      fn(err, {});
    }
  });
};
/*---------------------------------------------------------------------------*/
// are we muted?
let muted = function(fn) {
  this.conn.send_command("status_", "request", "ssap://audio/getStatus", null, function(err, response){
    if (!err) {
      fn(false, !!response.payload.mute);
    } else {
      fn(true, response);
    }
  });
};
/*---------------------------------------------------------------------------*/
// get volume as 0..100 if not muted
// if muted then volume is -1
let volume = function(fn) {
  // this.conn.send_command("status_", "subscribe", "ssap://audio/getVolume", null, function(err, response){
  this.conn.send_command("status_", "request", "ssap://audio/getVolume", null, function(err, response){
  // {"type":"response","id":"status_1","payload":{"muted":false,"scenario":"mastervolume_tv_speaker","active":false,"action":"requested","volume":7,"returnValue":true,"subscribed":true}}
    if (!err) {
      var muted = response.payload.muted;
      var ret = -1;
      if (!muted) {
        ret = response.payload.volume;
      }
      fn(false, ret);
    } else {
      fn(true, response);
    }
  });
};
/*---------------------------------------------------------------------------*/
let set_volume = function(volumelevel, fn) {
  console.dt_log("LGTV set volume: " + volumelevel);
  let vol = 0;
  if (typeof volumelevel === 'string') {
    vol = parseInt(volumelevel);
  } else {
    vol = volumelevel;
  }

  if (typeof vol !== 'number') {
    fn(true, "volume must be a number");

  } else if(vol < 0 || vol > 100) {
    fn(true, "volume must be 0..100");

  } else {
    this.conn.send_command("", "request", "ssap://audio/setVolume", JSON.stringify({volume: vol}), fn);
  }
};
/*---------------------------------------------------------------------------*/
let input_media_play = function(fn) {
  this.conn.send_command("", "request", "ssap://media.controls/play", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_media_stop = function(fn) {
  this.conn.send_command("", "request", "ssap://media.controls/stop", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_media_pause = function(fn) {
  this.conn.send_command("", "request", "ssap://media.controls/pause", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_media_rewind = function(fn) {
  this.conn.send_command("", "request", "ssap://media.controls/rewind", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_media_forward = function(fn) {
  this.conn.send_command("", "request", "ssap://media.controls/fastForward", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_channel_up = function(fn) {
  this.conn.send_command("", "request", "ssap://tv/channelUp", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_channel_down = function(fn) {
  this.conn.send_command("", "request", "ssap://tv/channelDown", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_three_d_on = function(fn) {
  this.conn.send_command("", "request", "ssap://com.webos.service.tv.display/set3DOn", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_three_d_off = function(fn) {
  this.conn.send_command("", "request", "ssap://com.webos.service.tv.display/set3DOff", null, fn);
};
/*---------------------------------------------------------------------------*/
// what does this return?
let get_status = function(fn) {
  this.conn.send_command("status_", "request", "ssap://audio/getStatus", null, fn);
  // this.conn.send_command("status_", "subscribe", "ssap://audio/getStatus", null, fn);
};
/*---------------------------------------------------------------------------*/
let sw_info = function(fn) {
  this.conn.send_command("sw_info_", "request", "ssap://com.webos.service.update/getCurrentSWInformation", null, fn);
// received: {"type":"response","id":"sw_info_0","payload":{"returnValue":true,"product_name":"webOS","model_name":"HE_DTV_WT1M_AFAAABAA","sw_type":"FIRMWARE","major_ver":"04","minor_ver":"41.32","country":"SE","device_id":"cc:2d:8c:cf:94:8c","auth_flag":"N","ignore_disable":"N","eco_info":"01","config_key":"00","language_code":"sv-SE"}}
};
/*---------------------------------------------------------------------------*/
let services = function(fn) {
  this.conn.send_command("services_", "request", "ssap://api/getServiceList", null, function(err, resp) {
    if (typeof fn === 'function') {
      if (!err) {
        try {
// received: {"type":"response","id":"services_1","payload":{"services":[{"name":"api","version":1},{"name":"audio","version":1},{"name":"media.controls","version":1},{"name":"media.viewer","version":1},{"name":"pairing","version":1},{"name":"system","version":1},{"name":"system.launcher","version":1},{"name":"system.notifications","version":1},{"name":"tv","version":1},{"name":"webapp","version":2}],"returnValue":true}}
          var services = resp.payload.services;
          fn(false, resp.payload.services);
        } catch(e) {
          console.dt_log("LGTV Error:" + e);
          fn(true, e);
        }
      } else {
        console.dt_log("LGTV Error:" + err);
        fn(true, err);
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
// get list of apps installed on tv
// eg live tv, youtube, spotify, ....
let apps = function(fn) {
  this.conn.send_command("launcher_", "request", "ssap://com.webos.applicationManager/listLaunchPoints", null, function(err, response) {
  // this.conn.send_command("launcher_", "subscribe", "ssap://com.webos.applicationManager/listLaunchPoints", null, function(err, response) {
    if (typeof fn === 'function') {
      if (!err) {
        try {
          // extract a nice and simple list of apps
          var applist = {};
          var launchpoints = response.payload.launchPoints;
          for (var i = launchpoints.length - 1; i >= 0; i--) {
            // var oneapp = {};
            // oneapp["title"] = launchpoints[i]["title"];
            // oneapp["id"] = launchpoints[i]["launchPointId"];
// {"removable":false,"largeIcon":"/mnt/otncabi/usr/palm/applications/com.webos.app.discovery/lgstore_130x130.png","vendor":"LGE","id":"com.webos.app.discovery","title":"LG Store","bgColor":"","vendorUrl":"","iconColor":"#cf0652","appDescription":"","params":{},"version":"1.0.18","bgImage":"/mnt/otncabi/usr/palm/applications/com.webos.app.discovery/lgstore_preview.png","icon":"http://lgsmarttv.lan:3000/resources/60ad544bd03663793dda37dbb21f10575408c73a/lgstore_80x80.png","launchPointId":"com.webos.app.discovery_default","imageForRecents":""},
            applist[launchpoints[i]["title"]] = launchpoints[i]["launchPointId"];
          }
          console.dt_log(`LGTV applist: ${applist}`);
          fn(false, applist);
        } catch(e) {
          console.dt_log("LGTV Error:" + e);
          fn(true, e);
        }
      } else {
        console.dt_log("LGTV Error:" + err);
        fn(true, err);
      }
    }
  });
};
/*---------------------------------------------------------------------------*/
function open_app_with_payload(payload, fn) {
    this.conn.send_command("", "request", "ssap://com.webos.applicationManager/launch", payload, null, fn);
}
/*---------------------------------------------------------------------------*/
let start_app = function(appid, fn) {
  console.dt_log("LGTV open app id: " + appid);

  this.conn.send_command("", "request", "ssap://system.launcher/launch", JSON.stringify({id: appid}), function(err, resp){
    if (!err) {
      if (resp.payload.errorCode) {
        fn(true, resp.payload.errorText);
        // {"type":"error","id":"1","error":"500 Application error","payload":{"returnValue":false,"errorCode":-101,"errorText":"\"bogusapp\" was not found OR Unsupported Application Type"}}
      } else {
        fn(false, {sessionId : resp.payload.sessionId});
      }
    } else {
      fn(err, resp);
    }
  });
};
/*---------------------------------------------------------------------------*/
let close_app = function(appid, fn) {
  console.dt_log("LGTV close app id: " + appid);

  this.conn.send_command("", "request", "ssap://system.launcher/close", JSON.stringify({id: appid}), function(err, resp){
    if (!err) {
      if (resp.payload.errorCode) {
        // Note: This error response may come as a result of trying to close an app
        // that is not already open
        // {"type":"error","id":"1","error":"500 Application error","payload":{"returnValue":false,"errorCode":-1000,"errorText":"Permission denied"}}
        fn(true, resp.payload.errorText);
      } else {
        fn(false, {sessionId : resp.payload.sessionId});
      }
    } else {
      fn(err, resp);
    }
  });
};
/*---------------------------------------------------------------------------*/
// an input pointer is like a mouse pointer
// first connect, then move/click, then disconnect when done
let input_pointer_connect = function(fn) {
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_pointer_move = function(dx, dy, fn) {
    // function sendMove(dx, dy) {
    //         pointerSocket.sendLogMessage('type:move\ndx:' + dx + '\ndy:' + dy + '\ndown:0\n\n')
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_pointer_click = function(fn) {
    // function sendClick() {
    //         pointerSocket.sendLogMessage('type:click\n\n')
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_pointer_disconnect = function(fn) {
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_pointer_scroll = function(dx, dy, fn) {
  // pointerSocket.sendLogMessage('type:scroll\ndx:0\ndy:' + dy + '\ndown:0\n\n')
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_text = function(text, fn) {
    // is this the right call for the right API here?
    // function sendInput(btype, bname) {
    //         pointerSocket.sendLogMessage('type:' + btype + '\nname:' + bname + '\n\n')
  if (typeof fn === 'function') {
    fn(true, {reason: "not implemented"});
  }
};
/*---------------------------------------------------------------------------*/
let input_enter = function(fn) {
  this.conn.send_command("", "request", "ssap://com.webos.service.ime/sendEnterKey", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_pause = function(fn) {
  this.conn.send_command("pause_", "request", "ssap://media.controls/pause", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_play = function(fn) {
  this.conn.send_command("play_", "request", "ssap://media.controls/play", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_stop = function(fn) {
  this.conn.send_command("stop_", "request", "ssap://media.controls/stop", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_volumeup = function(fn) {
  this.conn.send_command("volumeup_", "request", "ssap://audio/volumeUp", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_volumedown = function(fn) {
  this.conn.send_command("volumedown_", "request", "ssap://audio/volumeDown", null, fn);
};
/*---------------------------------------------------------------------------*/
let input_backspace = function(count, fn) {
  var c = count === undefined ? 1 : count;
  this.conn.send_command("", "request", "ssap://com.webos.service.ime/deleteCharacters", {"count": c}, fn);
};
/*---------------------------------------------------------------------------*/
// open the youtube app, using the youtube id
let open_youtube_at_id = function(video_id, fn) {
  var vurl = "http://www.youtube.com/tv?v=" + video_id;
  open_youtube_at_url(vurl, fn);
};
/*---------------------------------------------------------------------------*/
// open the youtube app, using full URL
let open_youtube_at_url = function(url, fn) {
  let youtube_appid = "youtube.leanback.v4";
  let payload = {id: youtube_appid, params : {contentTarget: url}};

  this.conn.send_command("", "request", "ssap://system.launcher/launch", JSON.stringify(payload), function(err, resp){
    if (!err) {
      if (resp.payload.errorCode) {
        fn(true, resp.payload.errorText);
        // {"type":"error","id":"1","error":"500 Application error","payload":{"returnValue":false,"errorCode":-101,"errorText":"\"bogusapp\" was not found OR Unsupported Application Type"}}
      } else {
        fn(false, {sessionId : resp.payload.sessionId});
      }
    } else {
      fn(err, resp);
    }
  });
};
/*---------------------------------------------------------------------------*/
let discover = function(fn) {
  this.discovery.discover(fn);
}
/*---------------------------------------------------------------------------*/
let disconnect = function(fn) {
  this.conn.disconnect(fn);
}
/*---------------------------------------------------------------------------*/
class lgtv {
  constructor() {
    this.conn = new comms.lgtv_connection();
    this.discovery = new discovery.lgtv_discovery();
  }

  set ip(newip) {
    this.conn.ip = newip;
  };

  set client_key(token) {
    console.dt_log(`setting client key ${token}`);
    this.conn.client_key = token;
  };
}
/*---------------------------------------------------------------------------*/
exports.lgtv = lgtv;

lgtv.prototype.discover = discover;
lgtv.prototype.disconnect = disconnect;

// unlimited power
lgtv.prototype.off = turn_off;

// sound volume related
lgtv.prototype.set_mute = set_mute;
lgtv.prototype.toggle_mute = toggle_mute;
lgtv.prototype.muted = muted; /* is the TV muted? */
lgtv.prototype.volume = volume; /* get volume */
lgtv.prototype.set_volume = set_volume; /* set volume */

// TV source input-related
lgtv.prototype.inputlist = inputlist; /* get list of inputs */
lgtv.prototype.input = input; /* get active input source */
lgtv.prototype.set_input = set_input; /* set input source */

// commands related to input such as remote control and text input
lgtv.prototype.input_enter = input_enter; /* remote control 'enter' */
lgtv.prototype.input_pause = input_pause; /* remote control 'pause' */
lgtv.prototype.input_play = input_play; /* remote control 'play' */
lgtv.prototype.input_stop = input_stop; /* remote control 'stop' */
lgtv.prototype.input_volumeup = input_volumeup; /* remote control 'volume up' */
lgtv.prototype.input_volumedown = input_volumedown; /* remote control 'volume down' */
lgtv.prototype.input_channel_up = input_channel_up; /* remote control volume up */
lgtv.prototype.input_channel_down = input_channel_down; /* remote control volume down */
lgtv.prototype.input_media_play = input_media_play; /* remote control play */
lgtv.prototype.input_media_stop = input_media_stop; /* remote control stop */
lgtv.prototype.input_media_pause = input_media_pause; /* remote control pause */
lgtv.prototype.input_media_rewind = input_media_rewind; /* remote control rewind */
lgtv.prototype.input_media_forward = input_media_forward; /* remote control forward */
lgtv.prototype.input_three_d_on = input_three_d_on; /* remote control 3d on */
lgtv.prototype.input_three_d_off = input_three_d_off; /* remote control 3d off */
lgtv.prototype.input_backspace = input_backspace; /* send 'backspace' */
lgtv.prototype.input_text = input_text; /* insert text */
lgtv.prototype.input_pointer_connect = input_pointer_connect; /* get pointer (like mouse pointer) */
lgtv.prototype.input_pointer_scroll = input_pointer_scroll; /* scroll */
lgtv.prototype.input_pointer_move = input_pointer_move; /* move the pointer */
lgtv.prototype.input_pointer_click = input_pointer_click; /* click pointer */
lgtv.prototype.input_pointer_disconnect = input_pointer_disconnect; /* disconnect the pointer */

// apps such as youtube, browser, and anything that may be installed
lgtv.prototype.open_youtube_at_id = open_youtube_at_id; /* open youtube at videoid */
lgtv.prototype.open_youtube_at_url = open_youtube_at_url; /* open youtube at url */
lgtv.prototype.open_browser_at = open_browser_at; /* open webbrowser at url */
lgtv.prototype.apps = apps; /* get list of apps */
lgtv.prototype.start_app = start_app; /* start app */
lgtv.prototype.close_app = close_app; /* close app */

// various status/state information
lgtv.prototype.get_status = get_status; /* get status information from TV */
lgtv.prototype.sw_info = sw_info; /* get software info such as webos version */
lgtv.prototype.services = services; /* get available services on the TV */
lgtv.prototype.show_float = show_float; /* show a small information box with text on the TV */

// set, get channels
lgtv.prototype.channellist = channellist; /* get list of channels available */
lgtv.prototype.channel = channel; /* get active channel */
lgtv.prototype.set_channel = set_channel; /* set active channel */
/*---------------------------------------------------------------------------*/
