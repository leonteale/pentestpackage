#!/bin/bash
# usage: $0 &lt;IP list file&gt;
#
# Strip Windowss CR EOL
dos2unix -q $1
#
ips=`cat $1`
while read ip
do
    lookup=`whois -r $ip | grep -E "inetnum:|netname:|descr:" | awk '{gsub("\t", "");print}' | awk '{gsub("inetnum:", "");print}' | awk '{gsub("netname:", "");print}' | awk '{gsub("descr:", "");print}' | tr -s " " | tr  "\n" "," | tr -d "\n"`



# Echo IP address, then the value of $lookup minus the last comma
echo "$ip,${lookup::-1}"
done <$1 
