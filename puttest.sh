#!/bin/bash

##########################################################################
# Coloured variables
##########################################################################
red=`echo -e "\033[31m"`
lcyan=`echo -e "\033[36m"`
yellow=`echo -e "\033[33m"`
green=`echo -e "\033[32m"`
blue=`echo -e "\033[34m"`
purple=`echo -e "\033[35m"`
normal=`echo -e "\033[m"`


read -e -p "Enter Target Web Server (e.g. http://domain.com:8080): " target

echo ""
echo "$yello Trying Method 1.. $normal"
echo ""
curl -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"/tmp/some-file.xml" $target/newpage
echo ""



echo ""
echo "$yello Trying Method 2.. $normal"
echo ""
curl -i -H "Accept: application/json" -X PUT -d "text or data to put" $target/new_page
echo ""


#echo ""
#echo "Trying Method X.."
#echo ""
#curl -X PUT -d "text or data to put" $target/destination_page
echo ""

