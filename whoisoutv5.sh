#!/bin/bash

#=====================================
# Author: G. Newman
# Date: 30-09-2016
# Ver: 0.4
# take any input file of IPs and run
# whois checks to capture required
# output to filename specified
#=====================================

#set variables
dir=$(pwd)
filext=_`date '+%d-%m-%Y_%H-%M'.txt`
filecsv=_`date '+%d-%m-%Y_%H-%M'.csv`
counter=1
lgreen='\033[1;32m'
nc='\033[0m' # No Color


#get working files
echo -e "============================================================\n"
echo -e "${lgreen}
                                   
    _/_/_/  _/_/_/_/_/    _/_/_/   
     _/        _/      _/          
    _/        _/      _/  _/_/     
   _/        _/      _/    _/      
_/_/_/      _/        _/_/_/       
                                   
                                   
${nc}\n"
echo "WHOIS CHECKING SCRIPT v0.4"
echo -e "\n"
echo "working directory:"$dir
echo -e "\n============================================================"
echo "available files"
ls -lht
echo -e "\n\n============================================================"
echo -n -e "Enter input filename\t:" 
read input
echo -n -e "Enter output filename\t:" 
read output
echo "============================================================"

# process the whois lookups
for i in $(cat $input);do 
{
echo -e "\nWHOIS test #:\t" $counter 
echo -e "IP Address:\t"$i ; whois $i | grep -i 'inetnum\|descr\|netname' ; echo -n -e "reverse ptr:\t"; nslookup $i | sed -n -e 's/^.*name = //p'
#counter=$((counter+1))
} | tee -a $output
counter=$((counter+1))
done

#file manipulation
cp $output ${output}${filext}

echo #,ip,inetnum,netname,descr,ptr > ${output}${filecsv}
x=0
for f in `cat ${output}${filext}`
do
   x=`expr $x + 1`
   echo Def,u$x,$f >> ${output}${filecsv}
done



#where to get the file
echo -e "\n============================================================"
echo -e "\nyour output file is here: \n"$dir"/"${output}${filext}"\n"
echo -e "your csv file is her: \n"$dir"/"${output}${filecsv}"\n"
echo "============================================================"
