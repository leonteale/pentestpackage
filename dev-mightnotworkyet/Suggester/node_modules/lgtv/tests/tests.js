

lgtv = require("./lg-webos-controller");
/*---------------------------------------------------------------------------*/
var input_enter_test = function() {
    lgtv.input_enter(function(err, response){
    if (!err) {
      console.log("input_enter succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_enter failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pause_test = function() {
    lgtv.input_pause(function(err, response){
    if (!err) {
      console.log("input_pause succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pause failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_play_test = function() {
    lgtv.input_play(function(err, response){
    if (!err) {
      console.log("input_play succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_play failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_stop_test = function() {
    lgtv.input_stop(function(err, response){
    if (!err) {
      console.log("input_stop succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_stop failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_volumeup_test = function() {
    lgtv.input_volumeup(function(err, response){
    if (!err) {
      console.log("input_volumeup succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_volumeup failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_volumedown_test = function() {
    lgtv.input_volumedown(function(err, response){
    if (!err) {
      console.log("input_volumedown succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_volumedown failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_channel_up_test = function() {
  lgtv.input_channel_up(function(err, response){
    if (!err) {
      console.log("input_channel_up_test succeeded");
    } else {
      console.log("input_channel_up_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_channel_down_test = function() {
  lgtv.input_channel_down(function(err, response){
    if (!err) {
      console.log("input_channel_down_test succeeded");
    } else {
      console.log("input_channel_down_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_media_play_test = function() {
  lgtv.input_media_play(function(err, response){
    if (!err) {
      console.log("input_media_play_test succeeded");
    } else {
      console.log("input_media_play_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_media_stop_test = function() {
  lgtv.input_media_stop(function(err, response){
    if (!err) {
      console.log("input_media_stop_test succeeded");
    } else {
      console.log("input_media_stop_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_media_pause_test = function() {
  lgtv.input_media_pause(function(err, response ){
    if (!err) {
      console.log("input_media_pause_test succeeded");
    } else {
      console.log("input_media_pause_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_media_rewind_test = function() {
  lgtv.input_media_rewind(function(err, response){
    if (!err) {
      console.log("input_media_rewind_test succeeded");
    } else {
      console.log("input_media_rewind_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_media_forward_test = function() {
  lgtv.input_media_forward(function(err, response ){
    if (!err) {
      console.log("input_media_forward_test succeeded");
    } else {
      console.log("input_media_forward_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_three_d_on_test = function() {
  lgtv.input_three_d_on(function(err, response){
    if (!err) {
      console.log("input_three_d_on_test succeeded");
    } else {
      console.log("input_three_d_on_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_three_d_off_test = function() {
  lgtv.input_three_d_off(function(err, response ){
    if (!err) {
      console.log("input_three_d_off_test succeeded");
    } else {
      console.log("input_three_d_off_test failed:");
      console.log(err.toString());
      console.log(response);
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_backspace_test = function() {
    lgtv.input_backspace(function(err, response){
    if (!err) {
      console.log("input_backspace succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_backspace failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_text_test = function() {
    lgtv.input_text(function(err, response){
    if (!err) {
      console.log("input_text succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_text failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pointer_connect_test = function(fn) {
    lgtv.input_pointer_connect(function(err, response){
    if (!err) {
      console.log("input_pointer_connect succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pointer_connect failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pointer_move_test = function() {
    lgtv.input_pointer_move(function(err, response){
    if (!err) {
      console.log("input_pointer_move succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pointer_move failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pointer_click_test = function() {
    lgtv.input_pointer_click(function(err, response){
    if (!err) {
      console.log("input_pointer_click succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pointer_click failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pointer_scroll_test = function(dx, dy) {
    lgtv.input_pointer_scroll(dx, dy, function(err, response){
    if (!err) {
      console.log("input_pointer_scroll succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pointer_scroll failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_pointer_disconnect_test = function() {
    lgtv.input_pointer_disconnect(function(err, response){
    if (!err) {
      console.log("input_pointer_disconnect succeeded:" + JSON.stringify(response));
    } else {
      console.log("input_pointer_disconnect failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var open_youtube_at_id_test = function(id) {
    lgtv.open_youtube_at_id(id, function(err, response){
    if (!err) {
      console.log("open_youtube_at_id succeeded:" + JSON.stringify(response));
    } else {
      console.log("open_youtube_at_id failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var open_youtube_at_url_test = function(url) {
    lgtv.open_youtube_at_url(url, function(err, response){
    if (!err) {
      console.log("open_youtube_at_url succeeded:" + JSON.stringify(response));
    } else {
      console.log("open_youtube_at_url failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var open_browser_at_test = function(url) {
    lgtv.open_browser_at(url, function(err, response){
    if (!err) {
      console.log("open_browser_at succeeded:" + JSON.stringify(response));
    } else {
      console.log("open_browser_at failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var apps_test = function() {
    lgtv.apps(function(err, response){
    if (!err) {
      console.log("apps succeeded:" + JSON.stringify(response));
    } else {
      console.log("apps failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var start_app_test = function(appid) {
    lgtv.start_app(appid, function(err, response){
    if (!err) {
      console.log("start_app succeeded:" + JSON.stringify(response));
    } else {
      console.log("start_app failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var close_app_test = function(appid) {
    lgtv.close_app(appid, function(err, response){
    if (!err) {
      console.log("close_app succeeded:" + JSON.stringify(response));
    } else {
      console.log("close_app failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var inputlist_test = function() {
    lgtv.inputlist(function(err, response){
    if (!err) {
      console.log("inputlist succeeded:" + JSON.stringify(response));
    } else {
      console.log("inputlist failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var input_test = function() {
    lgtv.input(function(err, response){
    if (!err) {
      console.log("input succeeded:" + JSON.stringify(response));
    } else {
      console.log("input failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var set_input_test = function(inputid) {
    lgtv.set_input(inputid, function(err, response){
    if (!err) {
      console.log("set_input succeeded:" + JSON.stringify(response));
    } else {
      console.log("set_input failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var muted_test = function() {
    lgtv.muted(function(err, response){
    if (!err) {
      console.log("muted succeeded:" + JSON.stringify(response));
    } else {
      console.log("muted failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var set_mute_test = function(mute) {
    lgtv.set_mute(mute, function(err, response){
    if (!err) {
      console.log("muted succeeded:" + JSON.stringify(response));
    } else {
      console.log("muted failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var toggle_mute_test = function() {
    lgtv.toggle_mute(function(err, response){
    if (!err) {
      console.log("muted succeeded:" + JSON.stringify(response));
    } else {
      console.log("muted failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var volume_test = function() {
    lgtv.volume(function(err, response){
    if (!err) {
      console.log("volume succeeded:" + JSON.stringify(response));
    } else {
      console.log("volume failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var set_volume_test = function(vl) {
    lgtv.set_volume(vl, function(err, response){
    if (!err) {
      console.log("set_volume succeeded:" + JSON.stringify(response));
    } else {
      console.log("set_volume failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var connect_test = function(hostname, fn) {
    lgtv.connect(hostname, function(err, response){
    if (!err) {
      console.log("connect succeeded:" + JSON.stringify(response));
    } else {
      console.log("connect failed:" + JSON.stringify(response));
    }
    fn(err);
  });
};
/*---------------------------------------------------------------------------*/
var disconnect_test = function() {
    lgtv.disconnect(function(err, response){
    if (!err) {
      console.log("disconnect succeeded:" + JSON.stringify(response));
    } else {
      console.log("disconnect failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var turn_off_test = function() {
    lgtv.turn_off(function(err, response){
    if (!err) {
      console.log("turn_off succeeded:" + JSON.stringify(response));
    } else {
      console.log("turn_off failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var get_status_test = function() {
    lgtv.get_status(function(err, response){
    if (!err) {
      console.log("get status succeeded:" + JSON.stringify(response));
    } else {
      console.log("get status failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var sw_info_test = function() {
    lgtv.sw_info(function(err, response){
    if (!err) {
      console.log("sw_info succeeded:" + JSON.stringify(response));
    } else {
      console.log("sw_info failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var services_test = function() {
    lgtv.services(function(err, response){
    if (!err) {
      console.log("services succeeded:" + JSON.stringify(response));
    } else {
      console.log("services failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
// test for getting the IP address after already having connected to the TV
var ip_test = function() {
    lgtv.ip(function(err, response){
    if (!err) {
      console.log("ip succeeded:" + JSON.stringify(response));
    } else {
      console.log("ip failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
// test for finding the IP address of the TV on the LAN
var discover_ip_test = function(retry_timeout_s, callback) {
    lgtv.discover_ip(retry_timeout_s, callback);
};
/*---------------------------------------------------------------------------*/
var connected_test = function() {
    lgtv.connected(function(err, response){
    if (!err) {
      console.log("connected succeeded:" + JSON.stringify(response));
    } else {
      console.log("connected failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var show_float_test = function() {
    lgtv.show_float("Test float succeded!", function(err, response){
    if (!err) {
      console.log("show_float succeeded:" + JSON.stringify(response));
    } else {
      console.log("show_float failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var channellist_test = function() {
    lgtv.channellist(function(err, response){
    if (!err) {
      console.log("channellist succeeded:" + JSON.stringify(response));
    } else {
      console.log("channellist failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var channel_test = function() {
    lgtv.channel(function(err, response){
    if (!err) {
      console.log("channel succeeded:" + JSON.stringify(response));
    } else {
      console.log("channel failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var set_channel_test = function(chid) {
    lgtv.set_channel(chid, function(err, response){
    if (!err) {
      console.log("set_channel succeeded:" + JSON.stringify(response));
    } else {
      console.log("set_channel failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
var temporarydbg_test = function() {
    lgtv.temporarydbg(function(err, response){
    if (!err) {
      console.log("tempdbg succeeded:" + JSON.stringify(response));
    } else {
      console.log("tempdbg failed:" + JSON.stringify(response));
    }
  });
};
/*---------------------------------------------------------------------------*/
// This is the list of functions that this file tests.

// exports.input_enter = input_enter; /* remote control 'enter' */
// exports.input_pause = input_pause; /* remote control 'pause' */
// exports.input_play = input_play; /* remote control 'play' */
// exports.input_stop = input_stop; /* remote control 'stop' */
// exports.input_volumeup = input_volumeup; /* remote control 'volume up' */
// exports.input_volumedown = input_volumedown; /* remote control 'volume down' */
// exports.input_backspace = input_backspace; /* send 'backspace' */
// exports.input_text = input_text; /* insert text */
// exports.input_pointer_connect = input_pointer_connect; /* get pointer (like mouse pointer) */
// exports.input_pointer_move = input_pointer_move; /* move the pointer */
// exports.input_pointer_click = input_pointer_click; /* click pointer */
// exports.input_pointer_disconnect = input_pointer_disconnect; /* disconnect the pointer */
// exports.open_youtube_at_id = open_youtube_at_id; /* open youtube at videoid */
// exports.open_youtube_at_url = open_youtube_at_url; /* open youtube at url */
// exports.open_browser_at = open_browser_at; /* open webbrowser at url */
// exports.apps = apps; /* get list of apps */
// exports.start_app = start_app; /* start app */
// exports.close_app = close_app; /* close app */
// exports.inputlist = inputlist; /* get list of inputs */
// exports.input = input; /* get active input source */
// exports.set_input = set_input; /* set input source */
// exports.set_mute = set_mute;
// exports.toggle_mute = toggle_mute;
// exports.muted = muted; /* is the TV muted? */
// exports.volume = volume; /* get volume */
// exports.set_volume = set_volume; /* set volume */
// exports.connect = connect; /* connect to TV */
// exports.disconnect = disconnect; /* disconnect from TV */
// exports.turn_off = turn_off; /* turn the TV off */
// exports.status = status; /* get status information from TV */
// exports.sw_info = sw_info; /* get software info such as webos version */
// exports.services = services; /* get available services on the TV */
// exports.ip = ip; /* get the TV IP-address */
// exports.connected = connected;  /* are we connected to the TV? */
// exports.show_float = show_float; /* show a small information box with text on the TV */
// exports.channellist = channellist; /* get list of channels available */
// exports.channel = channel; /* get active channel */
// exports.set_channel = set_channel; /* set active channel */

/*---------------------------------------------------------------------------*/
var retry_timeout = 10;
discover_ip_test(retry_timeout, function(err, ipaddr) {
  if (err) {
    console.log("Failed to find TV IP address on the LAN. Verify that TV is on, and that you are on the same LAN/Wifi.");
  } else {
    console.log("TV ip addr is: " + ipaddr);
  }
});


connect_test("192.168.1.86", function(err){
  if (!err) {
    setTimeout(function() {
      // disconnect_test();  // funkade inte
      // events.js:72
      //         throw er; // Unhandled 'error' event
      //               ^
      // Error: first argument must be a valid error code number
      //     at Sender.close (/Users/marcuslunden/Dropbox/Syncfolder/Syncfolder/node.js/rest-kodi-webostv-controller/node_modules/ws/lib/Sender.js:44:49)
      //     at WebSocket.close (/Users/marcuslunden/Dropbox/Syncfolder/Syncfolder/node.js/rest-kodi-webostv-controller/node_modules/ws/lib/WebSocket.js:117:18)
      //     at Object.disconnect (/Users/marcuslunden/Dropbox/Syncfolder/Syncfolder/node.js/rest-kodi-webostv-controller/lg-webos-controller.js:239:6)
      //     at disconnect_test (/Users/marcuslunden/Dropbox/Syncfolder/Syncfolder/node.js/rest-kodi-webostv-controller/test-lg-webos-controller.js:267:10)
      //     at null._onTimeout (/Users/marcuslunden/Dropbox/Syncfolder/Syncfolder/node.js/rest-kodi-webostv-controller/test-lg-webos-controller.js:421:7)
      //     at Timer.listOnTimeout [as ontimeout] (timers.js:110:15)
      setTimeout(function() {
        console.log("-----------exiting.");
        process.exit(0);
      }, 1000);
    }, 5000);

    // input_test();
    // input_text_test();
    input_pointer_connect_test(function(err, resp){
      if (!err) {
        // move the pointer a bit
        input_pointer_move_test(10, 10, function(err, resp){
          // then scroll
          if (!err) {
            input_pointer_scroll_test(function(err, resp){
              if (!err) {
                // click it
                input_pointer_click_test(function(err, resp){
                  if (!err) {
                    // finally disconnect
                    input_pointer_disconnect_test(function(err, resp){
                      if (!err) {
                        console.log("input pointer all OK!");
                      }
                    });
                  }
                }); // input_pointer_click_test
              }
            }); // input_pointer_scroll_test
          }
        }); //input_pointer_move_test
      }
    }); // input_pointer_connect_test

    // open_youtube_at_id_test("IEVE3KSKQ0o");
    // open_youtube_at_id_test("bogus");
    // open_youtube_at_url_test("https://www.youtube.com/watch?v=IEVE3KSKQ0o");
    // open_youtube_at_url_test("www.youtube.com/watch?v=IEVE3KSKQ0o");
    // open_youtube_at_url_test("bogus");

    // ip_test();
    // connected_test();
    // channellist_test();
    // apps_test();

    // tested and working as expected------------
    // input_stop_test();
    // input_enter_test();
    // input_backspace_test();
    // input_pause_test();

    // input_channel_up_test();
    // input_channel_down_test();
    // input_three_d_on_test();
    // input_three_d_off_test();
    // input_media_play_test();
    // input_media_pause_test();
    // input_media_stop_test();
    // input_media_rewind_test();
    // input_media_forward_test();

    // open_browser_at_test("www.google.com");
    // set_channel_test("0_3_10_0_0_65535_0");
    // set_channel_test("boguschannel"); // should fail
    // channel_test();
    // sw_info_test();
    // services_test();
    // show_float_test();
    // turn_off_test();
    // apps_test();
    // muted_test();
    // input_play_test();
    // input_volumeup_test();
    // input_volumedown_test();

    // set_volume_test(-2); // should fail
    // set_volume_test(101); // should fail
    // set_volume_test("osijdfosdn"); // should fail
    // set_volume_test(); // should fail
    // set_volume_test(0);
    // set_volume_test(10);
    // volume_test();
    // toggle_mute_test();
    // set_mute_test(true);
    // set_mute_test(false);
    // set_mute_test(243); // not boolean -> should fail

    // start_app_test("youtube.leanback.v4"); // open youtube
    // start_app_test("com.webos.app.livetv"); // open TV channel
    // start_app_test("bogusapp");
    // close_app_test("youtube.leanback.v4");

    // get_status_test(); // gives audio status, should instead give other status right?
    // inputlist_test();
    // set_input_test("HDMI_1");
    // set_input_test("bogus_input"); // should fail

    // temporarydbg_test();
  }
});
/*---------------------------------------------------------------------------*/






