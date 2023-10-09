lgtv = require("lgtv");
/*---------------------------------------------------------------------------*/
var args = process.argv.slice(2);
var vol = 10;
if (args.length > 0) {
  try {
    vol = parseInt(args[0]);
  } catch(error) {
  }
}

var retry_timeout = 10;
var run_test = function() {
    lgtv.discover_ip(retry_timeout, function(err, ipaddr) {
      if (err) {
        console.log("Failed to find TV IP address on the LAN. Verify that TV is on, and that you are on the same LAN/Wifi.");
    
      } else {
        console.log("Found TV at address " + ipaddr + ", running example.");
        lgtv.connect(ipaddr, function(err, response){
          if (!err) {
            console.log("setting volume to:" + vol);
            lgtv.set_volume(vol, function(err, response){
              lgtv.disconnect();
            });
          }
        });
      }
    });
};

run_test();
