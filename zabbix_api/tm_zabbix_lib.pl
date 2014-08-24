#!/usr/bin/perl
#
# tm_zabbix_libi.pl
#
# This is meant to be a library of subroutines making use of the simple wrapper to provide the advanced functions to manage
#    Zabbix deploments
#
#    Ken Wan - 1/8/2012
#       Get authentication hash value with new_request first, then generl requests are served via simple_request
# 
#       hostgroup_host is implemented to ensure all templates of a specified HostGroup do get linked up to all its Hosts
#
# 21/8/2012 : Version with log_change added to save old value required for possible reversed action, currently to the stdout 

use strict;

require "tm_zabbix_api.pl";

my $url;


#
# Subroutine to return a string of pickout values delimited by $delim (default is ' ') from a given string
#
sub retrieve_list {
   my $instring= shift;
   my $pickout= shift;
   my $delim= shift;
   my $excluded= shift;

   my $lres="";
   $delim=' ' if !$delim;

   if ($pickout) {
      my @output = split(/,/,$instring);
      my $picks;
      foreach(@output){
         $picks=$_;
         if ($picks =~ m/"${pickout}"/){
            $picks=~ s/"//g;
            $picks=~ s/.*${pickout}://g;
            $picks=~ s/.*\{//g;
            $picks=~ s/\}.*//g;
            $lres .= "${picks}${delim}" if (${picks} ne ${excluded});
         }
      }
   }
  return $lres;

}

#
# log the change for recovery if required
#
sub log_change {
   my $change= shift;
   my $old= shift;

   print "\n";
   print "!!!'".$change."!!!'";
   print "'".$old."'";
   print "\n";

}


#
# Subroutine to ensure templates of a given host group do get linked to its host members
#
sub hostgroup2_host {

   my $lauth= shift;
   my $hstgrp= shift;

   my $result= 0;
#
# Get all hosts into a string delimited by '|' pls for the given host group
#
   my $lres=simple_request($lauth,'hostgroup.get','"groupids": ["'.${hstgrp}.'"],"output": "value","select_hosts":"refer"');
   my $hostlist=retrieve_list($lres,'hostid','|');
#   print "\nHost list for hostgroup $hstgrp : $hostlist\n";

#
# Get all templates into a string delimited by '|' pls for the given host group
#
   $lres=simple_request($lauth,'hostgroup.get','"groupids": ["'.${hstgrp}.'"],"output": "value","select_templates":"refer"');
   my $templatelist=retrieve_list($lres,'templateid','|');
#   print "\nTemplate list for hostgroup $hstgrp : $templatelist\n";
#
# Loop thru the template list pls
#
   my $templateid;
   my $tmphstlist;
   my $missedlist;
   my $newlist;
   my @output = split(/\|/,"$templatelist");
   foreach (@output){
#
# Get all hosts linked to a template into a string delimited by '|' pls
#
      $templateid=$_;
      $lres=simple_request($lauth,'template.get','"templateids": ["'.${templateid}.'"],"output": "value","select_hosts": "refer"');
      $tmphstlist=retrieve_list($lres,'hostid','|',${templateid});
#      print "\nHost list linked to a template ${templateid} : $tmphstlist\n";
#
# check any missing one please
#
      $missedlist='';
      foreach (split(/\|/,"$hostlist")) {
         $missedlist .= "$_|" if (!($tmphstlist =~ m/$_/));
      }
#
# Take any action if required ... 
#
#
      if ($missedlist) {
         print "\n+++ The missing host list for template $templateid : ${missedlist}\n";
#
# construct the final list in correct format to assign via a template.update request
#
         foreach (split(/\|/,"${missedlist}${tmphstlist}")) {
            $newlist .= '{"hostid": "'.$_.'"},';
         }
         chop($newlist);   # remove the last ',' character
#print "\n---New List : $newlist===\n";
#
# Assign it !
#
        $lres=simple_request($lauth,'template.update','"templateid": "'.${templateid}.'","hosts": ['.${newlist}.']');
        print "\nResult for setting the new Host list linked to a template ${templateid} : $lres\n";
        log_change('template.update::'.'"templateid": "'.${templateid}.'","hosts": ['.${newlist}.']','Old host list::'.$tmphstlist);
        $result= 1;
      }
   }

   return $result;

}


########################################################################################################

1;

