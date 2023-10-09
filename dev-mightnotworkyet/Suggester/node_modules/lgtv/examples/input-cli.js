/*---------------------------------------------------------------------------*/
/* 
Use this example to set an input, eg
  node input-cli.js HDMI_1
  node input-cli.js HDMI_2
  node input-cli.js TV
when using TV, we need to start the TV app (here the analog TV, perhaps digital
TV needs a different app).
 */
/*---------------------------------------------------------------------------*/
lgtv = require("lg");
/*---------------------------------------------------------------------------*/
var args = process.argv.slice(2);
var input = "HDMI_1";
if (args.length > 0) {
    input = args[0];
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
            if (input === "TV") {
              // special case, needs to start an app
              lgtv.start_app("com.webos.app.livetv", function(err, response){
                if (!err) {
                  lgtv.disconnect();
                }
              });
          } else {
              lgtv.set_input(input, function(err, response){
                if (!err) {
                  lgtv.disconnect();
                }
              });
            }
          }
        });
      }
    });
};

run_test();
