#!/usr/bin/perl
( $ip1, $ip2, $ip3, $ip4, $mask ) = split(/[\.\/]/,$ARGV[0]);
$start=((int($ip1)<<24)+(int($ip2)<<16)+(int($ip3)<<
8)+int($ip4))&~((1<<(32-int($mask)))-1);
$end=((int($ip1)<<24)+(int($ip2)<<16)+(int($ip3)<<8)+int($ip4))|((1<<(32-int($mask)))-1);
for($n = $start; $n<=$end; $n++){
printf("%d.%d.%d.%d\n",($n>>24)&0xff,($n>>16)&0xff,($n>>8)&0xff,$n&0xff);}