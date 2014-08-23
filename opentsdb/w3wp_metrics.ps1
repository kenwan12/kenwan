#
# w3wp_metrics.ps1 [metric_set [sleep]]
#
# Version 1.0 - 9/7/2014 Ken Wan
# Version 2.1.1 - 21/7/2014 - use get_tags function from globals.ps1
# 

##if ( $args.count -ne 1 ) {
##   "Syntax: w3wp_metrics.ps1 [metric_set [sleep]]"
##   return
##}

# - ttfile as $args[0].tt - but not used
#
$_sleep=$args[1]
if (-Not $_sleep ) { $_sleep=30 }

#
$_BASEDIR="C:\Program Files\OpenTSDB"
# #$_BASEDIR=(pwd).Path
. "$_BASEDIR\globals.ps1"

##
#
$lhost=($env:computername).tolower()

$tags=get_tags($lhost)
# Add more tags here to $tags if wanted

#
$_IIS="C:\windows\system32\inetsrv"

### Main Loop ###

$www=&"$_IIS\appcmd.exe" list site
if (! $www) {
   write-host "--- No Web Site ?! ---"
   exit
}

while ( 1 ) {

   $start=get-date

# W3WP processes
   $w3wps=&"$_IIS\appcmd.exe" list wp
   $wps = @{}
   if ( $w3wps ) {
      foreach ($line in $w3wps) {
         $_lpid=$line.split('"')[1]
         $_lsite=$line.split(':')[1].split(')')[0]
         $wps[$_lpid] = "$_lsite"

# #   if ( $line -and ("$line" -match ":$Site\)") ) { ... }

      }
   }

#
$pids2keys=(get-counter '\.NET CLR Memory(w3wp*)\Process ID' -MaxSamples 1).Readings
#
if ( $pids2keys ) {
   $p2ks = @{}
   $k2s = @{}
   foreach ($line in $pids2keys) {
      $all=$line.Split(':')
#
      $line0=$all[0]
      $wpsite=$line0.split('(')[1].split(')')[0]
      $allwps="$wpsite"
      for ($i=1; $i -lt $all.Count; $i++) {
         $j=$all[$i]
         $k=$j.split("`n")
         $_pid=$k[1]
#
         if ( $_pid ) {
            $p2ks[$_pid]="$wpsite"
            $ks=$wps[$_pid]
            $k2s[$wpsite]="$ks"
         }
#
         $allwps="${allwps},${_pid}"
         if ( $k[3] ) {
            $wpsite=$k[3]
            $wpsite=$wpsite.split('(')[1].split(')')[0]
            $allwps="${allwps},${wpsite}"
         }
      }
   }
}
# #$allwps

##
## for W3WP processes
##

if ( $wps ) {

$metrics=gc "$_CONF\w3wpps.tt"
foreach ($_lpid in $wps.keys ) {

   $p=get-process -id $_lpid

   foreach ($mline in $metrics) {
      $_key=$mline.split('|')[0]
      $metric=$mline.split('|')[1]
      $_type=$mline.split('|')[2]

      $value = iex "`$p.$_key"

      if ( ! $value ) { $value=0 }

      $epoch=get-date -Uformat "%s"
      $epoch=($epoch -split '\.',2)[0]

# # echo output # #
      $_lsite=$wps[$_lpid]

$_lsite=$_lsite.tolower()
$tags=$tags.tolower()

      "$metric $epoch $value host=$lhost type=$_type instance=$_lsite $tags"
   }
}

}

##
#
# Get metrics and output values
#
# #   if ( $line -and ("$line" -match ":$Site\)") ) { ... }

if ( $wps -and $k2s ) {

$metrics=gc "$_CONF\w3wpgc.tt"
foreach ($mline in $metrics) {
#
   $key=$mline.split('|')[0]
   $metric=$mline.split('|')[1]
   $_type=$mline.split('|')[2]

   $_type = $_type -replace ('[# :]','_')
   $_type = $_type -replace ('^__','')
   $_type = $_type -replace ('__','_')

   foreach ($sname in $k2s.keys) {
         $ss=$k2s[$sname]
         if (-Not $ss ) { continue }
         $_key = $key -replace ('\.\.\.',$sname)

         $rec=get-counter "$_key"

         $sdate=[string]$rec.timestamp

         $epoch=get-date -Uformat "%s"
         $epoch=($epoch -split '\.',2)[0]

         $readings=$rec.readings.split(":")
         $values=$readings[1].split("`n")
         $value=$values[1]
         if ( ! $value ) { $value=0 }

# # echo output # #

$ss=$ss.tolower()
$tags=$tags.tolower()

         "$metric $epoch $value host=$lhost type=$_type instance=$ss $tags"
   }
}

}
#

   $end=get-date

   $diff = $end - $start
   $left = $_sleep - $diff.Seconds
   if ( $left -gt 0 ) { start-sleep $left }

} # end of while

#