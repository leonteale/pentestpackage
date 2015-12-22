#!/bin/bash

#Pulls the credentials (searchable) from the plesk PSA database. Also determins what version of plesk is running to get the correct command to retrieve the password > version 10.3
# Usage: ./Plesk-credetial-gatherer.sh
#


while :
do
clear
echo "######################"
echo "* "$blue MENU$normal" *"
echo "*--------------------*"
echo "* 1) FTP *"
echo "* 2) Email *"
echo "* 3) Search *"
echo "* 4) Plesk Pass *"
echo "* 5) Power user mode *"
echo "* *"
echo "* 0) exit *"
echo "######################"

read opt
case $opt in

1) mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT login AS FTP_USER,password AS FTP_PASS,home AS DOMAIN_ROOT,accounts.id,sys_users.account_id FROM accounts, sys_users WHERE accounts.id=sys_users.account_id;"
read enterkey;;

2) mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT accounts.id, mail.mail_name, accounts.password, domains.name FROM domains LEFT JOIN mail ON domains.id = mail.dom_id LEFT JOIN accounts ON mail.account_id = accounts.id;"
read enterkey;;

3)
echo "############################"
echo "* Search in: *"
echo "****************************"
echo "* 1) FTP *"
echo "* 2) EMAIL *"
echo "* 3) ALL *"
echo "############################"
read option
case $option in

1) echo "Enter Search Term"
read search;
mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT login AS FTP_USER,password AS FTP_PASS,home AS DOMAIN_ROOT,accounts.id,sys_users.account_id FROM accounts, sys_users WHERE accounts.id=sys_users.account_id;" | grep "$search" | awk '{ print "User: "$1 "\n" "Pass: "$2 "\n" "Home_Path: "$3"\n"}';
read enterkey;;

2) echo "Enter Search Term"
read search;
mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT accounts.id, mail.mail_name, accounts.password, domains.name FROM domains LEFT JOIN mail ON domains.id = mail.dom_id LEFT JOIN accounts ON mail.account_id = accounts.id;" | grep "$search" | awk '{ print $2"@"$4 " " "\n" "Pass:"$3"\n"}';
read enterkey;;
3) echo "Enter Search Term"
read search;
echo ""
echo "FTP"
mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT login AS FTP_USER,password AS FTP_PASS,home AS DOMAIN_ROOT,accounts.id,sys_users.account_id FROM accounts, sys_users WHERE accounts.id=sys_users.account_id;" | grep "$search" | awk '{ print "User: "$1 "\n" "Pass: "$2 "\n" "Home_Path: "$3"\n"}';
echo ""
echo "EMAIL"
mysql -uadmin psa -p`cat /etc/psa/.psa.shadow` -e "SELECT accounts.id, mail.mail_name, accounts.password, domains.name FROM domains LEFT JOIN mail ON domains.id = mail.dom_id LEFT JOIN accounts ON mail.account_id = accounts.id;" | grep "$search" | awk '{ print $2"@"$4 " " "\n""Pass:"$3 "\n"}';
read enterkey;;
esac;;

4) /usr/local/psa/bin/admin --show-password;
read enterkey;;

5)
echo "############################"
echo "* Power User mode: *"
echo "****************************"
echo "* 1) On *"
echo "* 2) Off *"
echo "* *"
echo "* 0) exit *"
echo "############################"
read option
case $option in
1) /usr/local/psa/bin/poweruser --on
echo "Power User mode On"
read enterkey;;
2) /usr/local/psa/bin/poweruser --off
echo "Power User mode Off"
read enterkey;;
0) echo "Exiting"
exit 1;;
*) echo "please Enter A Valid Option"
read enterkey;;
esac;;
0) echo "Exiting"
exit 1;;
*) echo "please Enter A Valid Option"
read enterkey;;

esac
done
