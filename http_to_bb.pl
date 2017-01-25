#!/usr/bin/perl

######################################################################################
# Script by http://www.garyshood.com
# Requires the lib-www perl module
# Runs under mod_perl with no changes. 
# Validates under HTML 4.01 Transitional.
# This is licensed under the BSD license.
# 
# Copyright (c) 2007, Gary's Hood
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or 
# other materials provided with the distribution.
# * Neither the name of the Gary's Hood nor the names of its contributors 
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                 
######################################################################################

use HTML::Entities;
use CGI;
$query = new CGI;
print $query->header();
$self = $ENV{SCRIPT_NAME};
$perl = $ENV{DOCUMENT_ROOT};

print <<STARTHTML;

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>HTML To BB Code Converter</title>
</head>
<body>

STARTHTML

if ($query->param("html")) {
	$html = $query->param("html");
}

if ($query->param("baseurl")) {
	$baseurl = $query->param("baseurl");
	$baseurl =~ encode_entities($baseurl);

	use Socket;
	if(inet_aton($baseurl)) {
		$ip = inet_ntoa(inet_aton($baseurl));
	}

	@banned = ('127.0.0.1', '192.168.', '172.');
	foreach $banned(@banned) {
		if($baseurl =~ $banned || $ip =~ $banned) {
			print "<p>No access allowed to that domain.</p>\n";
			print "<p>$ip</p>\n";
			exit 0;
		}
	}
	
	if($baseurl !~ /http:\/\// && $baseurl !~ /https:\/\//) {
		$baseurl = "http://$baseurl";
	}
	
	use LWP::Simple;
	$target_file = $baseurl;
	my $file = get($target_file);
	if($file == "") {
		#$file = "Site not found.";
	}
	$html = $file;
}

@domain = split(/\//,$baseurl);
if(@domain > 3) {
	pop(@domain);
}

$store = "";
foreach $base(@domain) {
	$store = "$store$base";
}

$store =~ s/http:/http:\/\//gi;
$store =~ s/https:/https:\/\//gi;
$baseurl = $store;

if (!$query->param("ascii")) {
	$html =~ s/\s\s+/\n/gi;
	$html =~ s/<pre(.*?)>(.*?)<\/pre>/\[code]$2\[\/code]/sgmi;
}

$html =~ s/\n//gi;
$html =~ s/\r\r//gi;
$html =~ s/$baseurl//gi;
$html =~ s/<h[1-7](.*?)>(.*?)<\/h[1-7]>/\n\[b]$2\[\/b]\n/sgmi;
$html =~ s/<p>/\n\n/gi;
$html =~ s/<br(.*?)>/\n/gi;
$html =~ s/<textarea(.*?)>(.*?)<\/textarea>/\[code]$2\[\/code]/sgmi;
$html =~ s/<b>(.*?)<\/b>/\[b]$1\[\/b]/gi;
$html =~ s/<i>(.*?)<\/i>/\[i]$1\[\/i]/gi;
$html =~ s/<u>(.*?)<\/u>/\[u]$1\[\/u]/gi;
$html =~ s/<em>(.*?)<\/em>/\[i]$1\[\/i]/gi;
$html =~ s/<strong>(.*?)<\/strong>/\[b]$1\[\/b]/gi;
$html =~ s/<cite>(.*?)<\/cite>/\[i]$1\[\/i]/gi;
$html =~ s/<font color="(.*?)">(.*?)<\/font>/\[color=$1]$2\[\/color]/sgmi;
$html =~ s/<font color=(.*?)>(.*?)<\/font>/\[color=$1]$2\[\/color]/sgmi;
$html =~ s/<link(.*?)>//gi;
$html =~ s/<li(.*?)>(.*?)<\/li>/\[\*]$2/gi;
$html =~ s/<ul(.*?)>/\[list]/gi;
$html =~ s/<\/ul>/\[\/list]/gi;
$html =~ s/<div>/\n/gi;
$html =~ s/<\/div>/\n/gi;
$html =~ s/<td(.*?)>/ /gi;
$html =~ s/<tr(.*?)>/\n/gi;

$html =~ s/<img(.*?)src="(.*?)"(.*?)>/\[img]$baseurl\/$2\[\/img]/gi;
$html =~ s/<a(.*?)href="(.*?)"(.*?)>(.*?)<\/a>/\[url=$baseurl\/$2]$4\[\/url]/gi;
$html =~ s/\[url=$baseurl\/http:\/\/(.*?)](.*?)\[\/url]/\[url=http:\/\/$1]$2\[\/url]/gi;
$html =~ s/\[img]$baseurl\/http:\/\/(.*?)\[\/img]/\[img]http:\/\/$1\[\/img]/gi;

$html =~ s/<head>(.*?)<\/head>//sgmi;
$html =~ s/<object>(.*?)<\/object>//sgmi;
$html =~ s/<script(.*?)>(.*?)<\/script>//sgmi;
$html =~ s/<style(.*?)>(.*?)<\/style>//sgmi;
$html =~ s/<title>(.*?)<\/title>//sgmi;
$html =~ s/<!--(.*?)-->/\n/sgmi;

$html =~ s/\/\//\//gi;
$html =~ s/http:\//http:\/\//gi;
$html =~ s/https:\//https:\/\//gi;

$html =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gsi;
$html =~ s/\r\r//gi;
$html =~ s/\[img]\//\[img]/gi;
$html =~ s/\[url=\//\[url=/gi;

if(!defined($html)) {
	$html = "<p>Site not found.</p>\n";
}

print <<MOREHTML;

<h2>HTML To BB Code Converter</h2>

<div id="download">
<div class="div_head">Download:</div>
<div class="pad">
<a href="download.php?d=zip">source.zip</a><br>
<a href="download.php?d=source">source.txt</a>
</div>
</div>
<br>

<div class="para">
<div class="div_head">Usage</div>
<div class="pad">
<p>
This is a form that will convert basic HTML into BB code that is used on various forums. It will strip out most HTML that cannot
be converted. 
</p>
</div>
</div>

<form method="post" action="$self">
<p><input type="checkbox" name="ascii">Check this for ASCII Art</p>

<p>Website: <input type="text" name="baseurl">
<input type="submit" value="Submit URL"></p>

HTML:<br>
<textarea cols="80" rows="30" name="html">$html</textarea>
<p><input type="submit" value="Submit HTML"></p>
</form>
</body>
</html>

MOREHTML

undef $html;
undef $baseurl;
undef $file;
