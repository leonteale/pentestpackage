'use strict';

// This file handles the connectionality to the TV, except for discovery.
/*---------------------------------------------------------------------------*/
// for reading and storing client key
let fs = require('fs');

// data structures
let lgtvdata = require('./lgtv-data.js');

let WebSocketClient = require('websocket').client;

// for matching ws request -- response
let eventemitter = new (require('events').EventEmitter);

// enable infinite number of listeners
eventemitter.setMaxListeners(0);

// once connected, store client key (retrieved from TV) in this file
const client_key_filename = "./client-key.txt";
/*---------------------------------------------------------------------------*/
// note, logging using custom console.dt_log defined in lgtv.js
/*---------------------------------------------------------------------------*/
// callback for when the connection is automatically terminated after a short period of time
let auto_kill_connection_callback = function() {
  console.dt_log(`LGTV automatically closing connection after idle timeout`);
  
  // if not connected, we can't run close on it
  if (this.clientconnection.close) {
    this.clientconnection.close();
  }
}
/*---------------------------------------------------------------------------*/
let ws_send = function(str){
    if (typeof str !== 'string') {
        throw new Error("ws send arg not a string");
    }

    // set timer to automatically disconnect
    if (this.auto_disconnect_timeout) {
      // reset timer
      clearTimeout(this.auto_disconnect_timer);
      this.auto_disconnect_timer = setTimeout(auto_kill_connection_callback.bind(this), this.auto_disconnect_timeout);
    }

    if (this.clientconnection.connected) {
      console.log(`we are connected`);
      this.clientconnection.send(str);

    } else {
      if (this.ip && this.connect_on_unconnected) {
        console.dt_log(`LGTV send but not connected, so we connect to: ${this.ip}`);
        this.establish_connection(this.ip, (err, res) => {
          if (!err) {
            this.clientconnection.send(str);
            return this.clientconnection.connected;
          } else {
            console.dt_log(err);
          }
        });
      } else {
        // no choice, no way to connect except a full discover
        throw new Error("ws send not connected");
      }
    }
    return this.clientconnection.connected;
};
/*---------------------------------------------------------------------------*/
// get the handshake string used for setting up the ws connection
let _handshake = function() {
  // lgtvdata.hello_again.replace("CLIENTKEYGOESHERE", "53540c95a0077f377b8aa7a98cf0eea1");

  if (this.clientkey) {
    console.dt_log("LGTV using set Client key:" + this.clientkey);
    return lgtvdata.hello_again.replace("CLIENTKEYGOESHERE", this.clientkey);

  } else if (fs.existsSync(client_key_filename)) {
    var ck = fs.readFileSync(client_key_filename);
    console.dt_log("LGTV using filesystem Client key:" + ck);
    return lgtvdata.hello_again.replace("CLIENTKEYGOESHERE", ck);

  } else {
    console.dt_log("LGTV no client key, pairing new.");
    return lgtvdata.hello;
  }

  throw new Error("no client key for handshake possible");
}
// ---------------------------------------------------------
// store the client key on disk so that we don't have to pair next time
function store_client_key(ck) {
  // console.dt_log("LGTV Storing client key:" + ck);
  fs.writeFileSync(client_key_filename, ck);
}
//------------------------------------------
let _close_connection = function(){
    console.dt_log("LGTV disconnecting");

    // if not connected, we can't run close on it
    if (this.clientconnection.close) {
      this.clientconnection.close();
    }

    // stop timer since we are already closed
    clearTimeout(this.auto_disconnect_timer);
};
/*---------------------------------------------------------------------------*/
// send a command to the TV after having established a paired connection
let send_command = function(prefix, msgtype, uri, payload, fn) {
  this.command_count++;
  let msg = `{"id":"${prefix}${this.command_count}","type":"${msgtype}","uri":"${uri}"`;
  if (typeof payload === 'string' && payload.length > 0) {
    msg += `,"payload":${payload}`;
  }
  msg += "}";
  console.dt_log("LGTV ---> Sending command:" + msg);

  // if we were provided a callback, we register an event emitter listener for this.
  // note: there is a clear risk of memory leaks should we have a lot of outstanding
  // requests that never gets responses as the listeners are only cleared on response
  // or websocket close and we never clear them.
  try {
    if (typeof fn === 'function') {
      console.dt_log(`LGTV *** event listener for ${prefix + this.command_count}: ${msg}`);
      eventemitter.once(prefix + this.command_count, function (message) {
        fn(false, message);
      });
    }
    this.ws_send(msg);

  } catch(err) {
    console.dt_log("LGTV Error, not connected to TV: " + err.toString());
    console.dt_log(err.stack);
    if (typeof fn === 'function') {
      fn(true, "not connected");
    }
  }
};
/*---------------------------------------------------------------------------*/
let _open_connection = function(host, fn){
    console.dt_log(`LGTV open connection to ${host}`);
    // let ip = clientconnection.remoteAddress;
    // clear connection
    this.clientconnection = {};
    this.clientconnection.remoteAddress = this.ip; // restore IP
    // console.dt_log(clientconnection);

    try {
      this.websocket_client.connect(host);
      fn(false, {});
    } catch(error) {
      fn(true, error.toString());
    }
};
/*---------------------------------------------------------------------------*/
// verify that the provided host string contains ws protocol and port 3000,
// valid input examples:
//    lgsmarttv.lan
//    192.168.1.86
//    192.168.1.86:3000
//    ws://192.168.1.86:3000
//    ws://192.168.1.86
// if protocol or port is lacking, they are added
// returns either the corrected host string

let _sanitize_host_string = function(hoststr)
{
  if (typeof(hoststr) !== 'string') {
    return undefined;
  }
  // starts with protocol
  if (hoststr.indexOf("ws://") !== 0) {
    hoststr = "ws://" + hoststr;
  }
  // ends with port
  if (hoststr.indexOf(":3000") !== (hoststr.length - 5)) {
    hoststr += ":3000";
  }

  return hoststr;
};
/*---------------------------------------------------------------------------*/
// Connect to TV using either a host string (eg "192.168.1.213", "lgsmarttv.lan")
// or undefined for using the default "lgsmarttv.lan"

let establish_connection = function(host, fn) {
  // if already connected, no need to connect again
  // (unless hostname is new, but this package is basically written for the usecase
  // of having a single TV on the LAN)
  if (this.connected() && this.handshaken) {
    console.dt_log("LGTV already connected");
    if (typeof fn === 'function') {
      fn(false, {});
    }
    return;
  }

  // sanitize and set hostname
  host = _sanitize_host_string(host) || this.wsurl;
  console.dt_log(`host is ${host}`);

  // open websocket connection and perform handshake
  this._open_connection(host, function(err, msg){
    if (!err) {
        // connection opened, and the ws connection callback will automatically
        // send the handshake, but we here register the listener for the response to
        // that handshake (should be moved for code clarity)
        eventemitter.once("register_0", function (message) {
          if (message.type === "response") {
            console.dt_log("LGTV uhoh, we reacted on the response, not registry");
            // here, we should await the next packet from the tv, which would be a register with a client key
          }
          let ck = message.payload["client-key"];
          let remoteerror = message.error;
          if (typeof ck === 'undefined') {
            console.dt_log("LGTV no client key. Error? " + remoteerror);

          } else {
            // if we not already have a client key set, we store this to disk
            // so the next time we can read it and do not need to re-pair




            // XXXXX "this" points wrong here I assume, since it's a callback
            if (!this.clientkey) {store_client_key(ck);}

            this.handshaken = true;
            console.dt_log("LGTV handshake done");
            if (typeof fn === 'function') {
              // XXXX here we should in some way pass the this
              console.log(`handshake done, now invoking callback`);
              fn(false, {});
            }
          }
          //  {"type":"registered","id":"register_0","payload":{"client-key":"a32c6abeab6a601d626ccdeb4749f0fa"}}
        });
    } else {
        console.dt_log("LGTV connection opened");
        if (typeof fn === 'function') {
          fn(true, msg);
        }
    }
  });
};
/*---------------------------------------------------------------------------*/
var connected = function() {
  if (this.clientconnection.connected) {
      console.dt_log("LGTV is disconnected");
      return false;
  }
  return this.clientconnection.connected;
};
/*---------------------------------------------------------------------------*/
var disconnect = function(fn) {
  console.dt_log("LGTV disconnecting...");

  this._close_connection();

  eventemitter.once("lgtv_ws_closed", function () {
    if(typeof fn === 'function') {
      fn(false);
    }
  });
};
/*---------------------------------------------------------------------------*/
let discover_ip = function(fn) {
  // XXX todo, add this from the lgtv discovery thing
  console.log("why are we running this discover ip?");
  if (fn) {fn("not implemented", undefined);}
}
/*---------------------------------------------------------------------------*/
let on_ws_connect_setup_callbacks_and_do_handshake = function(connection) {
  console.log(`ws on connect callback`);

  console.dt_log('LGTV ws connected to ' + connection.remoteAddress);
  this.clientconnection = connection;

  // store the IP so we have it, in case we didn't already have it
  this.ip = connection.remoteAddress;
  console.log(`remote IP is ${this.ip}`);

  // set timer to automatically disconnect
  if (this.auto_disconnect_timeout) {
    // reset timer
    clearTimeout(this.auto_disconnect_timer);
    this.auto_disconnect_timer = setTimeout(auto_kill_connection_callback.bind(this), this.auto_disconnect_timeout);
  }

  // on connect, set up error handler
  this.clientconnection.on('error', (error) => {
      console.dt_log("LGTV Connection Error: " + error.toString());
      // stop timer since we are disconnecting
      clearTimeout(this.auto_disconnect_timer);

      // emit event, although should we indicate this was an error?
      eventemitter.emit("lgtv_ws_closed");
      if (this.clientconnection.close) {
        // XXXXX should we do this? ok to close on an error connection?
        this.clientconnection.close();
      }
      this.clientconnection = {};
      throw new Error("Websocket connection error:" + error.toString());
  });

  // on connect, set up close handler
  this.clientconnection.on('close', () => {
      // stop timer - perhaps this cb is invoked if closed by remote, in which
      // case we need to stop timers here too
      clearTimeout(this.auto_disconnect_timer);
      console.dt_log('LGTV connection closed');
      this.clientconnection = {};
      eventemitter.emit("lgtv_ws_closed");
  });
  //--------------------------------------------------------------------------
  // on connect, set up message received handler
  this.clientconnection.on('message', (message) => {
      // here, we receive an object, of which one property is an object, so we parse it
      if (message.type === 'utf8') {
          try {
            let utf_payload = JSON.parse(message.utf8Data);
            console.dt_log(`LGTV <--- received utf8: ${utf_payload}`);
            // console.dt_log(utf_payload);
            console.dt_log(`LGTV emitting ${utf_payload.id}`);
            eventemitter.emit(utf_payload.id, utf_payload);
          } catch(err) {
            console.dt_log(`LGTV <--- received, failed JSON parse: ${message.toString()} error ${err}}`);
          }
      } else {
          console.dt_log(`LGTV <--- received utf8: ${message}`);
      }
  });

  // when connecting the first time, we will either request new
  // client key, or use exising one. This call gives us the right
  // handshake for this.
  if (!this.handshake) {
    console.log(`we have no handshake, since no key. Falling back.`);
    this.handshake = this._handshake();
  }
  console.dt_log(`LGTV Sending handshake: ${this.handshake}`);
  this.clientconnection.send(this.handshake);
  // connection.sendUTF(hs); // works as well
}
/*---------------------------------------------------------------------------*/
class lgtv_connection {
  set client_key(token) {
    console.log(`lgtv connection setting client key ${token}`);
    this.clientkey = token;
    this.handshake = this._handshake();
  };

  constructor() {
    this.wsurl = 'ws://lgsmarttv.lan:3000';

    // have we sent the handshake and gotten a client key?
    this.handshaken = false;

    // set the client key, which also determines the handshake used when connecting
    // over websockets

    // hold the clientkey, if we are already paired with the TV
    // fallbacks are 1) reading from disk, 2) new pairing with TV using dialog on tv
    this.clientkey = undefined;
    this.handshake = undefined;

    // set the IP for the TV, fallback is using the URL, or user may search for TV,
    // but that is not automatic
    this.ip = undefined;

    // flag for, if we are trying to send but are not connected, should we then
    // do a connect (true), or drop and signal error (false)?
    this.connect_on_unconnected = true;

    // internal: counter to match response--request for event emitter
    this.command_count = 0;

    // internal: holds the ws connection
    this.clientconnection = {};
    // this.clientconnection.remoteAddress = undefined;

    // internal: to save latency, if we are using the tv we keep the connection
    // open for a while and automatically disconnect after a while. This timer
    // handles that. Each send from us to tv reset the timer.
    this.auto_disconnect_timeout = 10000;
    this.auto_disconnect_timer = {};

    // internal: for communication with TV
    this.websocket_client = new WebSocketClient();
    this.websocket_client.on('connectFailed', (error) => {
        // XXXX implement retry connect timer to reconnect;
        // have a counter to throw after too many reconnect attempts
        console.dt_log('LGTV Connect Failed Error: ' + error.toString());
        
        // this happens if tv is not in ON state, in which we'll get an 
        // "Error: connect EHOSTUNREACH 192.168.10.110:3000"
        // throw new Error("LGTV failed to connect");
    });

    // store the connection in a variable with larger scope so that we may later
    // refer to it and close connection.
    this.websocket_client.on('connect', on_ws_connect_setup_callbacks_and_do_handshake.bind(this));
  }
}

exports.lgtv_connection = lgtv_connection;

// send a command, ie the default way to tell the TV stuff
lgtv_connection.prototype.send_command = send_command;

// internal, really, but useful for hackz
lgtv_connection.prototype.ws_send = ws_send;

 /* discover the TV IP address */
lgtv_connection.prototype.discover_ip = discover_ip;

 /* connect to TV */
lgtv_connection.prototype.establish_connection = establish_connection;

  /* are we connected to the TV? */
lgtv_connection.prototype.connected = connected;

 /* disconnect from TV */
lgtv_connection.prototype.disconnect = disconnect;





// internal
lgtv_connection.prototype._open_connection = _open_connection;
lgtv_connection.prototype._handshake = _handshake;
lgtv_connection.prototype._close_connection = _close_connection;
/*---------------------------------------------------------------------------*/
