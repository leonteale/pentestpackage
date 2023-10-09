'use strict';
/*---------------------------------------------------------------------------*/
// for SSDP discover of TV on the LAN
var dgram = require('dgram');
const { StringDecoder } = require('string_decoder');
const decoder = new StringDecoder('utf8');
/*---------------------------------------------------------------------------*/
// note, logging using custom console.dt_log defined in lgtv.js
/*---------------------------------------------------------------------------*/
// send the SSDP discover message that the TV will respond to.
let _send_ssdp_discover = function()
{
  if (!this.ssdp_socket._receiving) {
    console.log(`ssdp discover socket not open, dropping tx`);
  } else {
    // these SSDP fields are all required
    let ssdp_msg = 'M-SEARCH * HTTP/1.1\r\n';
    ssdp_msg += 'HOST: 239.255.255.250:1900\r\n';
    ssdp_msg += 'MAN: "ssdp:discover"\r\n';
    ssdp_msg += 'MX: 5\r\n';
    ssdp_msg += "ST: urn:dial-multiscreen-org:service:dial:1\r\n";
    ssdp_msg += "USER-AGENT: iOS/5.0 UDAP/2.0 iPhone/4\r\n\r\n";
    let message = Buffer.from(ssdp_msg);

    console.dt_log(`LGTV SSDP discover sent to ${this.ssdp_ip}:${this.ssdp_port}`);
    this.ssdp_socket.send(message, 0, message.length, this.ssdp_port, this.ssdp_ip, function(err, bytes) {
        if (err) throw err;
    });
  }
};
/*---------------------------------------------------------------------------*/
// open an UDP socket in order to use a hard-coded SSDP discovery to find the
// TV on the local network
let discover = function(cb)
{
  // when socket open, start discovery probing
  this.ssdp_socket.on('listening', () => {
    // send first ssdp discover
    this._send_ssdp_discover();

    // setup retry timer
    if (this.retry_interval) {
      this.retry_timer = setInterval(() => {
        this._send_ssdp_discover();
      }, this.retry_interval);
    }

    // setup timeout timer
    if (this.retry_timeout) {
      this.retry_timeout_timer = setTimeout(()=> {
        // no answer in a while, clean up and return that we have failed
        console.dt_log(`timed out, gave up`);
        clearTimeout(this.retry_timer);
        clearTimeout(this.retry_timeout_timer);
        this.ssdp_socket.close();

        // signal error
        if (cb) {
          cb("timeout", null);
        }
      }, this.retry_timeout);
    }
  });

  // scan incoming messages for the magic string
  this.ssdp_socket.on('message', (message, remote) => {
    console.log(`got some message from ${remote.address}`);
    console.log(message);
    console.log(decoder.write(message));
    let decodedmess = decoder.write(message);
    if(decodedmess.indexOf("LG Smart TV") >= 0) {
      // success
      clearTimeout(this.retry_timer);
      clearTimeout(this.retry_timeout_timer);
      console.dt_log("LGTV SSDP discovery got answer from an LG TV");
      this.ssdp_socket.close();
      if (cb) {
        cb(false, remote.address);
      }
    } else {
      // no match. For comparison, this is the Chromecast responding:
      // HTTP/1.1 200 OK
      // CACHE-CONTROL: max-age=1800
      // DATE: Sun, 29 Mar 2020 11:34:50 GMT
      // EXT:
      // LOCATION: http://192.168.10.111:8008/ssdp/device-desc.xml
      // OPT: "http://schemas.upnp.org/upnp/1/0/"; ns=01
      // 01-NLS: [....]
      // SERVER: Linux/3.8.13+, UPnP/1.0, Portable SDK for UPnP devices/1.6.18
      // X-User-Agent: redsonic
      // ST: urn:dial-multiscreen-org:service:dial:1
      // USN: uuid:[...]::urn:dial-multiscreen-org:service:dial:1
      // BOOTID.UPNP.ORG: 2504
      // CONFIGID.UPNP.ORG: 3
    }
  });
  
  this.ssdp_socket.bind(); // listen to 0.0.0.0:random
};
/*---------------------------------------------------------------------------*/
// connect and power related
/*---------------------------------------------------------------------------*/
class lgtv_discovery {
  constructor() {
    // default multicast destination IP and port
    this.ssdp_ip = "239.255.255.250";
    this.ssdp_port = 1900;

    // how often to resend SSDP query until tv responds
    this.retry_interval = 500;
    this.retry_timer;

    // when to give up
    this.retry_timeout = 2000;
    this.retry_timeout_timer;

    this.ssdp_socket = dgram.createSocket('udp4');
  }
}

lgtv_discovery.prototype.discover = discover;

// internal
lgtv_discovery.prototype._send_ssdp_discover = _send_ssdp_discover;

exports.lgtv_discovery = lgtv_discovery;
/*---------------------------------------------------------------------------*/
