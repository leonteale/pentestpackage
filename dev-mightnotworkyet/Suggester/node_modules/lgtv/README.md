# NOT MAINTAINED anymore

Sorry, I just haven't got the time to keep up. I've gotten a couple of awesome PRs in which this project has been cleaned up and refactored - perhaps one of those is where you may want to go. That being said, this works for me with my TV. Best of luck, and thanks for the great PRs!

//Marcus


# LGTV

## Installation

`npm install lgtv` and set up the TV per below.

## Prerequisites

First, the device (eg your computer) must be on the same network as the TV. Second, you should enable the TV to broadcast itself as `lgsmarttv.lan` in the local network. This setting is under `Network/LG Connect Apps`. This is necessary in order for this module to find the TV on the network and allow apps to connect. You also need to be on the same network as the TV.

## Quick start

The first time you run it against the TV, you need to give the program access to the TV by answering `yes` to the prompt on the TV. From then on, the received client key is used so you don't have to perform this step again.

Then, follow some of the examples to begin with, eg `examples/show-float.js` to show a float pop up on the screen:

```js
lgtv = require("lgtv");

var tv_ip_address = "192.168.1.214";
lgtv.connect(tv_ip_address, function(err, response){
  if (!err) {
    lgtv.show_float("It works!", function(err, response){
      if (!err) {
        lgtv.disconnect();
      }
    }); // show float
  }
}); // connect
```

Now that you can do this, we also can change input source to eg TV/HDMI/whatever, list and open apps, open browser, open Youtube app, change channel/volume, turn off the TV etc. Basically the only thing that doesn't work right now is a) turning on the TV, which doesn't seem possible this way, and b) opening Youtube at an URL (coming soon).

### Using a hostname or IP-address of the TV

The above uses a default hostname, `lgsmarttv.lan`. Your TV may not follow that, or you may have more than one TV. Then you can specify the hostname like below. The hostname can be eg `kitchen-tv.lan`, `192.168.1.214` or similar.

```js
lgtv = require("lgtv");

lgtv.connect("192.168.1.214", function(err, response){
  if (!err) {
    lgtv.show_float("It works!", function(err, response){
      if (!err) {
        lgtv.disconnect();
      }
    }); // show float
  }
}); // connect
```

### Auto-detecting the TV on the network

If you don't know the IP of the TV, or the hostname, you can scan for it using the `discover_ip()` function like below. Beware that this takes 3-4 seconds for the round-trip times (the TV is slow to respond to the SSDP discover probe).

```js
lgtv = require("lgtv");

var retry_timeout = 10; // seconds
lgtv.discover_ip(retry_timeout, function(err, ipaddr) {
  if (err) {
    console.log("Failed to find TV IP address on the LAN. Verify that TV is on, and that you are on the same LAN/Wifi.");
  } else {
    console.log("TV ip addr is: " + ipaddr);
  }
});
```

If you want to autodiscover each time, this would work,

```js
lgtv = require("lgtv");

var retry_timeout = 10; // seconds
lgtv.discover_ip(retry_timeout, function(err, ipaddr) {
  if (err) {
    console.log("Failed to find TV IP address on the LAN. Verify that TV is on, and that you are on the same LAN/Wifi.");

  } else {
    lgtv.connect(ipaddr, function(err, response){
      if (!err) {
        lgtv.show_float("Found you!", function(err, response){
          if (!err) {
            lgtv.disconnect();
          }
        }); // show float
      }
    }); // connect
  }
});
```

## Introduction

This module is targeting the LG Smart TVs running WebOS, ie later 2014 or 2015 models.
Previous models used another OS and other protocols and won't work with this.

* Controlling the TV means
  * (finding the TV on your local network)
  * establishing a connection, ie successful handshake
  * controlling input source, volume, etc

There is some useful information out there already:

* LG TV:
  * LG remote app on android store
    - you could sniff traffic on network as it interacts with TV
    - you could reverse engineer by downloading .apk, run dex2jar etc etc
  * LG remote app by third-party developers
      - https://github.com/CODeRUS/harbour-lgremote-webos
        -seems like it is written with deep knowledge of WebOS internals
  * look through the open source SDK's and API's published by LG
      - https://github.com/ConnectSDK/Connect-SDK-Android-Core

## Motivation

There is an LG remote control app for Android, but it is horribly slow. Also, it is very generic and mirrors the physical remote control. With this module I can chain a set of commands such as change input to HDMI_1 and set volume 10 and make them happen programmatically instead of finding the right buttons in the app. I also combine this with a corresponding module for controlling a Kodi media player.

# Communication overview

I recently bought a new TV, a LG 60LB870V, which is a 2014 TV running WebOS 1.x. The same day I got the TV, I ran `nmap` on the TV and `Wireshark` on the network the TV was connected to, with the following results (full results at the bottom).

```
Port Scanning host results
     Open TCP Port:     1061        
     Open TCP Port:     1424        
     Open TCP Port:     1900        ssdp
     Open TCP Port:     1970        
     Open TCP Port:     3000        ws
     Open TCP Port:     3001        wss
     Open TCP Port:     9955
     Open TCP Port:     9998        
     Open TCP Port:     18181       
     Open TCP Port:     36866
```

Through Wireshark, I saw the TV sending UDP:

  * SSDP (simple service discovery protocol) to `239.255.255.250:1900`, presenting several SSDP endpoints
  * `192.168.1.255:9956` and `224.0.0.113:9956`. Port `9956` and the contents show this
    is `alljoyn`-traffic, something I haven't encountered before but is a service
    discovery protocol of some kind according to Wikipedia. The addresses are multicast/broadcast.

In the TV menus I had also enabled `zeroconf` meaning I can now address the TV by an
address valid in the local network, by default `lgsmarttv.lan` which is found by mDNS. This setting
is, IIRC, under `Network/LG Connect Apps`.

The TV IP address can otherwise be found using SSDP; send this:

```
'M-SEARCH * HTTP/1.1\r\n'
'HOST: 239.255.255.250:1900\r\n'
'MX: 30\r\n'
'MAN: "ssdp:discover\r\n"'
'ST: urn:lge-com:service:webos-second-screen:1\r\n\r\n'
```

to `udp://239.255.255.250:1900`, then the TV will respond.
This may be an alternative schema: `urn:schemas-upnp-org:device:MediaRenderer:1`.

## Pairing and communication

Most of the communication is over websockets on port 3000, or 3001.

The application must pair with the TV in order to be allowed to control it.
The pairing handshake used here is a hardcoded handshake retrieved from another LG remote control application,
which in turn seems to have retrieved it from the official LG remote control app. No fields
can be changed or the handshake will fail, and only basic commands are allowed. The handshake
contains a base-64 signature, which if "debased" starts `{"algorithm":"RSA-SHA256","keyId":"test-signing-cert","signatureVersion":1}`.
This may just be a hash of the signature, perhaps in JSON format, but I haven't persued this further.

If the signing information is not included, or something is changed - thus invalidating the signing - the handshake will
still succeed, but some commands are not permitted (such as getting information about the TV software).

After the handshake, the rest of the communication stays over the same websocket socket. Data and commands are sent
in cleartext JSON format, eg

```
{"type":"response","id":"status_0","payload":{"scenario":"mastervolume_tv_speaker","active":false,"action":"requested","volume":0,"returnValue":true,"subscribed":true,"mute":false}}
```

The `type` is either (at least, there may be more),

* `request` - a single request, eg get volume
* `response` - response to a request, or subscription event
* `subscribe` - subscribe to a topic ie get notifications when something happens, eg channel is changed
* `unsubscribe` - unsubscribe a subscribed topic

The `id` is a concatenation of the command and a message counter, like so:

```
Request:
{"type":"request","id":"status_3", ...}

Response:
{"type":"response","id":"status_3", ...}
```

This is used so that a request can be matched with a response.

----------------------------------------------------------

# Complete nmap report

Command: `sudo nmap -sV -p 1-65535 192.168.1.86`

Result:

```
Starting Nmap 6.40-2 ( http://nmap.org ) at 2014-12-30 14:13 CET
Nmap scan report for 192.168.1.86
Host is up (0.028s latency).
Not shown: 65525 closed ports
PORT      STATE SERVICE     VERSION
1126/tcp  open  tcpwrapped
1261/tcp  open  tcpwrapped
1843/tcp  open  tcpwrapped
1900/tcp  open  upnp?
3000/tcp  open  ppp?
3001/tcp  open  ssl/nessus?
9955/tcp  open  unknown
9998/tcp  open  distinct32?
18181/tcp open  opsec-cvp?
36866/tcp open  unknown
6 services unrecognized despite returning data. If you know the service/version, please submit the following fingerprints at http://www.insecure.org/cgi-bin/servicefp-submit.cgi :
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port1900-TCP:V=6.40-2%I=7%D=12/30%Time=54A2A53E%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x20Tue,
SF:\x2030\x20Dec\x202014\x2013:13:48\x20GMT\r\nConnection:\x20close\r\n\r\
SF:n")%r(HTTPOptions,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x20Tue,
SF:\x2030\x20Dec\x202014\x2013:13:53\x20GMT\r\nConnection:\x20close\r\n\r\
SF:n")%r(FourOhFourRequest,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x
SF:20Tue,\x2030\x20Dec\x202014\x2013:13:53\x20GMT\r\nConnection:\x20close\
SF:r\n\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3000-TCP:V=6.40-2%I=7%D=12/30%Time=54A2A543%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Tue,\x2030\x20
SF:Dec\x202014\x2013:13:53\x20GMT\r\nConnection:\x20close\r\n\r\nHello\x20
SF:world\r\n")%r(HTTPOptions,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Tue,\x
SF:2030\x20Dec\x202014\x2013:13:53\x20GMT\r\nConnection:\x20close\r\n\r\nH
SF:ello\x20world\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3001-TCP:V=6.40-2%T=SSL%I=7%D=12/30%Time=54A2A561%P=x86_64-apple-da
SF:rwin10.8.0%r(GetRequest,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Tue,\x20
SF:30\x20Dec\x202014\x2013:14:23\x20GMT\r\nConnection:\x20close\r\n\r\nHel
SF:lo\x20world\r\n")%r(HTTPOptions,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20
SF:Tue,\x2030\x20Dec\x202014\x2013:14:23\x20GMT\r\nConnection:\x20close\r\
SF:n\r\nHello\x20world\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port9955-TCP:V=6.40-2%I=7%D=12/30%Time=54A2A573%P=x86_64-apple-darwin10
SF:.8.0%r(Kerberos,F,"ERROR\x20Unknown\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port9998-TCP:V=6.40-2%I=7%D=12/30%Time=54A2A543%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,5C8,"HTTP/1\.1\x20200\x20OK\r\nConnection:\x20close\r
SF:\nContent-Length:\x201395\r\nContent-Type:\x20text/html\r\n\r\n<!DOCTYP
SF:E\x20html>\n<html><head>\n<script\x20type=\"text/javascript\">\nfunctio
SF:n\x20createPageList\(\)\x20{\n\x20\x20\x20\x20var\x20xhr\x20=\x20new\x2
SF:0XMLHttpRequest;\n\x20\x20\x20\x20xhr\.open\(\"GET\",\x20\"/pagelist\.j
SF:son\"\);\n\x20\x20\x20\x20xhr\.onload\x20=\x20function\(e\)\x20{\n\x20\
SF:x20\x20\x20\x20\x20\x20\x20if\x20\(xhr\.status\x20==\x20200\)\x20{\n\x2
SF:0\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20pages\x20=\x20JSON\
SF:.parse\(xhr\.responseText\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20if\x20\(pages\.length\)\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20\x20\x20\x20document\.getElementById\(\"noPageNotice\"\)\.
SF:style\.display\x20=\x20\"none\";\n\n\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20var\x20pageList\x20=\x20document\.createElement\(\"ol\"\);
SF:\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20for\x20\(var\x20i\x20
SF:in\x20pages\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20var\x20link\x20=\x20document\.createElement\(\"a\"\);\n\x2
SF:0\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20tit
SF:le\x20=\x20pages\[i\]\.title\x20\?\x20pages\[i\]\.title\x20:\x20\(\"Pag
SF:e\x20\"\x20\+\x20\(Number\(pages\[i\]\.id\)\)\);\n\x20\x20\x20\x20\x20\
SF:x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20url\x20=\x20pages\[i\
SF:]\.url;\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x
SF:20link\.appendChild\(document\.createTextNode\(title\x20\+\x20\(url\x20
SF:\?\x20\(\"\x20\[\"\x20\+\x20url\x20\+\x20\"\]\"\)\x20:\x20\"\"\x20\)\)\
SF:);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20lin
SF:k\.setAttribute\(\"hre")%r(HTTPOptions,5C8,"HTTP/1\.1\x20200\x20OK\r\nC
SF:onnection:\x20close\r\nContent-Length:\x201395\r\nContent-Type:\x20text
SF:/html\r\n\r\n<!DOCTYPE\x20html>\n<html><head>\n<script\x20type=\"text/j
SF:avascript\">\nfunction\x20createPageList\(\)\x20{\n\x20\x20\x20\x20var\
SF:x20xhr\x20=\x20new\x20XMLHttpRequest;\n\x20\x20\x20\x20xhr\.open\(\"GET
SF:\",\x20\"/pagelist\.json\"\);\n\x20\x20\x20\x20xhr\.onload\x20=\x20func
SF:tion\(e\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20if\x20\(xhr\.status\x20
SF:==\x20200\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x
SF:20pages\x20=\x20JSON\.parse\(xhr\.responseText\);\n\x20\x20\x20\x20\x20
SF:\x20\x20\x20\x20\x20\x20\x20if\x20\(pages\.length\)\n\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20document\.getElementById\
SF:(\"noPageNotice\"\)\.style\.display\x20=\x20\"none\";\n\n\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20var\x20pageList\x20=\x20document\.cre
SF:ateElement\(\"ol\"\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
SF:for\x20\(var\x20i\x20in\x20pages\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20var\x20link\x20=\x20document\.createE
SF:lement\(\"a\"\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20\x20var\x20title\x20=\x20pages\[i\]\.title\x20\?\x20pages\[i\]\.
SF:title\x20:\x20\(\"Page\x20\"\x20\+\x20\(Number\(pages\[i\]\.id\)\)\);\n
SF:\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20
SF:url\x20=\x20pages\[i\]\.url;\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20\x20\x20\x20\x20link\.appendChild\(document\.createTextNode\(tit
SF:le\x20\+\x20\(url\x20\?\x20\(\"\x20\[\"\x20\+\x20url\x20\+\x20\"\]\"\)\
SF:x20:\x20\"\"\x20\)\)\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20link\.setAttribute\(\"hre");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port36866-TCP:V=6.40-2%I=7%D=12/30%Time=54A2A543%P=x86_64-apple-darwin1
SF:0.8.0%r(GetRequest,198,"HTTP/1\.1\x20200\x20OK\r\nContent-Type:\x20text
SF:/xml\r\nDate:\x20Tue,\x2030\x20Dec\x202014\x2013:13:53\x20GMT\r\nConnec
SF:tion:\x20close\r\n\r\n<\?xml\x20version=\"1\.0\"\x20encoding=\"UTF-8\"\
SF:?><service\x20xmlns=\"urn:dial-multiscreen-org:schemas:dial\"><name></n
SF:ame><options\x20allowStop=\"true\"/><state>running</state><link\x20rel=
SF:\"run\"\x20href=\"run\"/><additionalData\x20xmlns=\"http://www\.youtube
SF:\.com/dial\"><screenId>lf85fem4srqg84i7vis9ppj0ie</screenId></additiona
SF:lData></service>")%r(FourOhFourRequest,52,"HTTP/1\.1\x20404\x20Not\x20F
SF:ound\r\nDate:\x20Tue,\x2030\x20Dec\x202014\x2013:13:59\x20GMT\r\nConnec
SF:tion:\x20close\r\n\r\n");
MAC Address: <redacted> (Unknown)

Service detection performed. Please report any incorrect results at http://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 209.82 seconds
```

Update, with the latest firmware as of today, the `1.4.0-2507(afro-ashley)`, the nmap looks like below. Also, I don't see it advertising itself over SSDP like before, nor answer to the ssdp query as it did before.

```
-[691]> sudo nmap -sV -p 1-65535 192.168.1.86
Password:

Starting Nmap 6.40-2 ( http://nmap.org ) at 2015-10-29 21:37 CET
Nmap scan report for 192.168.1.86
Host is up (0.0076s latency).
Not shown: 65525 closed ports
PORT      STATE SERVICE     VERSION
1701/tcp  open  tcpwrapped
1742/tcp  open  tcpwrapped
1881/tcp  open  tcpwrapped
1900/tcp  open  upnp?
3000/tcp  open  ppp?
3001/tcp  open  ssl/nessus?
9955/tcp  open  unknown
9998/tcp  open  distinct32?
18181/tcp open  opsec-cvp?
36866/tcp open  unknown
6 services unrecognized despite returning data. If you know the service/version, please submit the following fingerprints at http://www.insecure.org/cgi-bin/servicefp-submit.cgi :
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port1900-TCP:V=6.40-2%I=7%D=10/29%Time=563283C6%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x20Thu,
SF:\x2029\x20Oct\x202015\x2020:38:26\x20GMT\r\nConnection:\x20close\r\n\r\
SF:n")%r(HTTPOptions,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x20Thu,
SF:\x2029\x20Oct\x202015\x2020:38:31\x20GMT\r\nConnection:\x20close\r\n\r\
SF:n")%r(FourOhFourRequest,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x
SF:20Thu,\x2029\x20Oct\x202015\x2020:38:31\x20GMT\r\nConnection:\x20close\
SF:r\n\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3000-TCP:V=6.40-2%I=7%D=10/29%Time=563283CB%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Thu,\x2029\x20
SF:Oct\x202015\x2020:38:31\x20GMT\r\nConnection:\x20close\r\n\r\nHello\x20
SF:world\r\n")%r(HTTPOptions,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Thu,\x
SF:2029\x20Oct\x202015\x2020:38:31\x20GMT\r\nConnection:\x20close\r\n\r\nH
SF:ello\x20world\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3001-TCP:V=6.40-2%T=SSL%I=7%D=10/29%Time=563283E8%P=x86_64-apple-da
SF:rwin10.8.0%r(GetRequest,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20Thu,\x20
SF:29\x20Oct\x202015\x2020:39:00\x20GMT\r\nConnection:\x20close\r\n\r\nHel
SF:lo\x20world\r\n")%r(HTTPOptions,58,"HTTP/1\.1\x20200\x20OK\r\nDate:\x20
SF:Thu,\x2029\x20Oct\x202015\x2020:39:00\x20GMT\r\nConnection:\x20close\r\
SF:n\r\nHello\x20world\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port9955-TCP:V=6.40-2%I=7%D=10/29%Time=563283D5%P=x86_64-apple-darwin10
SF:.8.0%r(Kerberos,F,"ERROR\x20Unknown\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port9998-TCP:V=6.40-2%I=7%D=10/29%Time=563283CB%P=x86_64-apple-darwin10
SF:.8.0%r(GetRequest,5C8,"HTTP/1\.1\x20200\x20OK\r\nConnection:\x20close\r
SF:\nContent-Length:\x201395\r\nContent-Type:\x20text/html\r\n\r\n<!DOCTYP
SF:E\x20html>\n<html><head>\n<script\x20type=\"text/javascript\">\nfunctio
SF:n\x20createPageList\(\)\x20{\n\x20\x20\x20\x20var\x20xhr\x20=\x20new\x2
SF:0XMLHttpRequest;\n\x20\x20\x20\x20xhr\.open\(\"GET\",\x20\"/pagelist\.j
SF:son\"\);\n\x20\x20\x20\x20xhr\.onload\x20=\x20function\(e\)\x20{\n\x20\
SF:x20\x20\x20\x20\x20\x20\x20if\x20\(xhr\.status\x20==\x20200\)\x20{\n\x2
SF:0\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20pages\x20=\x20JSON\
SF:.parse\(xhr\.responseText\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20if\x20\(pages\.length\)\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20\x20\x20\x20document\.getElementById\(\"noPageNotice\"\)\.
SF:style\.display\x20=\x20\"none\";\n\n\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20var\x20pageList\x20=\x20document\.createElement\(\"ol\"\);
SF:\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20for\x20\(var\x20i\x20
SF:in\x20pages\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x2
SF:0\x20\x20\x20var\x20link\x20=\x20document\.createElement\(\"a\"\);\n\x2
SF:0\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20tit
SF:le\x20=\x20pages\[i\]\.title\x20\?\x20pages\[i\]\.title\x20:\x20\(\"Pag
SF:e\x20\"\x20\+\x20\(Number\(pages\[i\]\.id\)\)\);\n\x20\x20\x20\x20\x20\
SF:x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20url\x20=\x20pages\[i\
SF:]\.url;\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x
SF:20link\.appendChild\(document\.createTextNode\(title\x20\+\x20\(url\x20
SF:\?\x20\(\"\x20\[\"\x20\+\x20url\x20\+\x20\"\]\"\)\x20:\x20\"\"\x20\)\)\
SF:);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20lin
SF:k\.setAttribute\(\"hre")%r(HTTPOptions,5C8,"HTTP/1\.1\x20200\x20OK\r\nC
SF:onnection:\x20close\r\nContent-Length:\x201395\r\nContent-Type:\x20text
SF:/html\r\n\r\n<!DOCTYPE\x20html>\n<html><head>\n<script\x20type=\"text/j
SF:avascript\">\nfunction\x20createPageList\(\)\x20{\n\x20\x20\x20\x20var\
SF:x20xhr\x20=\x20new\x20XMLHttpRequest;\n\x20\x20\x20\x20xhr\.open\(\"GET
SF:\",\x20\"/pagelist\.json\"\);\n\x20\x20\x20\x20xhr\.onload\x20=\x20func
SF:tion\(e\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20if\x20\(xhr\.status\x20
SF:==\x20200\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x
SF:20pages\x20=\x20JSON\.parse\(xhr\.responseText\);\n\x20\x20\x20\x20\x20
SF:\x20\x20\x20\x20\x20\x20\x20if\x20\(pages\.length\)\n\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20document\.getElementById\
SF:(\"noPageNotice\"\)\.style\.display\x20=\x20\"none\";\n\n\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20var\x20pageList\x20=\x20document\.cre
SF:ateElement\(\"ol\"\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20
SF:for\x20\(var\x20i\x20in\x20pages\)\x20{\n\x20\x20\x20\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20\x20\x20\x20\x20var\x20link\x20=\x20document\.createE
SF:lement\(\"a\"\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20\x20var\x20title\x20=\x20pages\[i\]\.title\x20\?\x20pages\[i\]\.
SF:title\x20:\x20\(\"Page\x20\"\x20\+\x20\(Number\(pages\[i\]\.id\)\)\);\n
SF:\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20var\x20
SF:url\x20=\x20pages\[i\]\.url;\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\
SF:x20\x20\x20\x20\x20\x20link\.appendChild\(document\.createTextNode\(tit
SF:le\x20\+\x20\(url\x20\?\x20\(\"\x20\[\"\x20\+\x20url\x20\+\x20\"\]\"\)\
SF:x20:\x20\"\"\x20\)\)\);\n\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x
SF:20\x20\x20\x20\x20link\.setAttribute\(\"hre");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port36866-TCP:V=6.40-2%I=7%D=10/29%Time=563283CB%P=x86_64-apple-darwin1
SF:0.8.0%r(GetRequest,145,"HTTP/1\.1\x20200\x20OK\r\nContent-Type:\x20text
SF:/xml\r\nDate:\x20Thu,\x2029\x20Oct\x202015\x2020:38:31\x20GMT\r\nConnec
SF:tion:\x20close\r\n\r\n<\?xml\x20version=\"1\.0\"\x20encoding=\"UTF-8\"\
SF:?><service\x20xmlns=\"urn:dial-multiscreen-org:schemas:dial\"><name></n
SF:ame><options\x20allowStop=\"true\"/><state>running</state><link\x20rel=
SF:\"run\"\x20href=\"run\"/><additionalData></additionalData></service>")%
SF:r(FourOhFourRequest,52,"HTTP/1\.1\x20404\x20Not\x20Found\r\nDate:\x20Th
SF:u,\x2029\x20Oct\x202015\x2020:38:36\x20GMT\r\nConnection:\x20close\r\n\
SF:r\n");
MAC Address: <redacted> (Unknown)

Service detection performed. Please report any incorrect results at http://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 180.22 seconds
```

