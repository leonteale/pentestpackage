#!/bin/bash
for ip in $(cat $1);

	do nslookup $ip > /tmp/rdns.txt
		if grep --quiet "name" /tmp/rdns.txt
			then 
				cat /tmp/rdns.txt | grep "name" | awk {'print $4'}
			else
				echo "No rDNS set"
		fi
	done
