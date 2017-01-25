<?php
  // File listings in current dir and walks all below
  echo "<pre>\n";
  echo "Self: ".$_SERVER["PHP_SELF"]."\n";
  $startdir = dirname( $_SERVER["SCRIPT_FILENAME"] ); 
  $startdir = "/var/www/wordpress";
  echo "Starting at $startdir\n";
  walkdir( $startdir );

  echo "</pre>\n";

  function walkdir( $dir ){
    $dh = opendir( $dir );
    $aDirs = array();
    $aFiles = array();
    while( false !== ( $file = readdir( $dh ) ) ){
      $file = trim( $file );
      if( $file == "." || $file == ".." ) continue;
      if( is_dir( $dir."/".$file ) ) $aDirs[] = $file;
      else $aFiles[] = $file;
    }
    closedir( $dh );
    foreach( $aFiles as $f ){
      echo "[f] $f\n";
    }
    foreach( $aDirs as $d ){
      echo "[d] $dir/$d\n";
      echo "<blockquote>";
      walkdir( $dir."/".$d );
      echo "</blockquote>";
    }
  }
?>
