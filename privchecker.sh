#/bin/bash
# By: Leon Teale (leonteale.co.uk)
#
#This script uses output from Enum4Linux to cross reference  users you have identified on a pentest to see what groups they relate too so you cna specify your efforts on particular accounts




## Setting Coloured variables
red=`echo -e "\033[31m"`
lcyan=`echo -e "\033[36m"`
yellow=`echo -e "\033[33m"`
green=`echo -e "\033[32m"`
blue=`echo -e "\033[34m"`
purple=`echo -e "\033[35m"`
normal=`echo -e "\033[m"`

#Variables 
groups=groups.txt
 
if [ ! -a $groups ]
	then
		echo -e "Domain Admins\nSQL" > $groups
fi

#Usage
if (( $# != 2 ))
	then
        echo "Usage: ./privcheker.sh users.txt enum.txt"
        exit 1
fi
 

#Main
clear
for user in `cat $1`;do
		echo ""
		echo "$yellow$user$normal has access to:"
		echo "$green"
		fgrep -w -f $1 $2 | awk {'print $NF, $0'} | sort | awk {' $1 =""; print'} | grep $user | cut -d \' -f 2 | grep -i -v 'rid' | grep -v '\$' | grep -v '\{' | sort -u
		echo "$normal"
done

if
		fgrep -w -f $1 $2 | awk {'print $NF, $0'} | sort | awk {' $1 =""; print'} | grep -f $groups > /dev/null 2>&1
	then
		echo "+---------------------------------------+"
		echo "|$yellow Possible$red High Privilaged$yellow Users Found!$normal|"
		echo "+---------------------------------------+"
		
		group=`fgrep -w -f $1 $2 | awk {'print $NF, $0'} | sort | awk {' $1 =""; print'} | grep -f $groups  | cut -d \( -f 1 | cut -d \' -f 2 | grep -i -v 'rid' | grep -v '\{' | sort -u `
		echo "Groups found: $red$group$normal"
		echo ""
		fgrep -w -f $1 $2 | sort | awk {' $1 =""; print'} | grep -f $groups | awk {'print $NF,"-" $0 '} | cut -d \( -f 1 | grep -i -v 'rid' | grep -v '\$' | grep -v '\{' | cut -d "\\" -f 2 | cut -d - -f 1 | column 
		echo ""
	else
		echo "+--------------------------------+"
		echo "|$green No High Privilaged Users Found$normal |"
		echo "+--------------------------------+"
		echo ""
fi
