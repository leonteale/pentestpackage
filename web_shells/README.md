web-shells
==========

This is a set of very simple web shells. Most I've written, some are by other authors (named in the source).

I don't recommend using these in a live environment unless you know what you're doing. Most of these have no authentication or restrictions in them and were designed to do simple jobs in the minimum time, primarily for virtual lab and exam usage.

For a much more thoroughly thought through set of web shells for a wider range of platforms, I recommend Laudanum: http://laudanum.inguardians.com/

## cmdshell.txt

Very simple PHP command shell. Executes whatever is in $_GET["cmd"] and outputs results to the page. You can probably do 90% of work just using this.

## mysqlshell.txt

Simple MySQL shell using ext/mysql functions for PHP<5.5. Provide the credentials and an SQL command and it will output the resultset in a table

## pdoshell.txt

Same as mysqlshell.txt but using PDO methods, which if installed on the remote server will allow querying of SQL Server, Oracle, Postgres, sqlite and MySQL databases. If there server is running PHP 5.5 or above, mysqlshell.txt won't work as the ext/mysql drivers won't be installed so you will need to use this one.

## aspxshell.aspx.txt

Written by lt@mac.hush.com. Not tried this out yet. Included for emergencies

## exectest.txt

Simply determine if a script is allowing you to execute arbitrary code. Display the path of the script

## filewrite.php

When this runs it base64 encodes a file on the local machine and writes it to the remote web server that you pass the URL of this script to. Can be used to upload arbitrary files, write new file contents etc.

## getpasswd.txt

Just output the contents of /etc/passwd. Useful if on time constraints or you're unable to send arguments to cmdshell 

## getsource.txt

As with getpasswd.txt, output the contents of a file

## phpinfo.txt

Just run phpinfo() and get a lot of useful server info

## treeview.txt

Recurse through all folders in the location this script ran and produce a file listing. More visual and quicker than exploring by commands.

## unix-privesc-check

A useful payload to check for privilege escalation vulnerabilities on the target machine. Taken from http://pentestmonkey.net/tools/audit/unix-privesc-check

## php-reverse_shell.txt

A very reliable reverse shell initiator. You can write reverse shells in much fewer lines of text but they won't work as well as this.
Also from http://pentestmonkey.net/tools/web-shells/php-reverse-shell

## xss_cookiestealer.php

For XSS attacks. This posts the value of a victim's cookies back to itself in base64 and decodes the output so you can spot the plaintext in HTTP traffic

## xss_contentstealer.php

Like xss_cookiestealer.php except it steals a specified piece of content from the injected page rather than a cookie
