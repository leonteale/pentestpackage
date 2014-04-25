#!/bin/bash

#Gets the urls that return a status 200 on port 443 and 80 when given a list of ips.
#
# Usage: ./web-service-finder.sh ips.txt
#
# By: Leon Teale (leonteale.co.uk)
#
echo ""

## Check for correct usage
if [ -z "$1" ];
		then
			echo "please provide some ips for the script"
			echo "   Usage: ./web-service-finder.sh ips.txt"
			echo ""
			
		else
			for ip in `cat $1`; do 
				echo "$ip";

				#Perform nmap to only gather ips that have port 443 open else the script can hang.
				nmap $ip -p 443 -o /dev/null | egrep open; done | grep -B 1 open > temp.txt; cat temp.txt | grep '[^\.][0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}[^\.]' > ips443.txt;
					for ip in `cat ips443.txt | sort -u`; do
						#Performs the last bit of the program using curl to grab the URL
						curl -k -sL -w "%{http_code} %{url_effective}\\n" "https://$ip"; done | grep "200 https"

			for ip in `cat $1`; do 
				echo "$ip";

				#Perform nmap to only gather ips that have port 80 open else the script can hang.
				nmap $ip -p 80 -o /dev/null | egrep open; done | grep -B 1 open > temp.txt; cat temp.txt | grep '[^\.][0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}[^\.]' > ips80.txt;
					for ip in `cat ips80.txt | sort -u`; do
						#Performs the last bit of the program using curl to grab the URL
						curl -k -sL -w "%{http_code} %{url_effective}\\n" "http://$ip"; done | grep "200 http"
fi


#clean up
rm ips80.txt
rm ips443.txt