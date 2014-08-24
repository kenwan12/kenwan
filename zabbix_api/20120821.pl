#require "tm_zabbix_api.pl";
require "tm_zabbix_lib.pl";
#api_init();
#api_init('localhost','admin','zabbix');
#api_init('localhost','apitest','Kenken\$\$');
api_init('localhost','ken.wan','...');
my $lauth=new_request();
#
#$lres=simple_request($lauth,'hostgroup.get','"output": "extend","filter": {"name": "winsys - tms - sseti - ams1"}');
$lres=simple_request($lauth,'hostgroup.get','"output": "extend","filter": {"name": "winsys - tms - www - lca6"}');
#print "\n$lres\n";
#
$lres=simple_request($lauth,'hostgroup.get','"output": "extend","templated_hosts":1');
$groupids=retrieve_list($lres,'groupid');
print $groupids;
foreach $groupid ( split(/ /,$groupids) ) {
   chomp($groupid);
   $groupid=~ s/ *//g;
   $groupname=retrieve_list(simple_request($lauth,'hostgroup.get','"output": "extend","filter": {"groupid": "'.${groupid}.'"}'),'name');
#  for Win... Host Groups please
   if ( ($groupname =~ m/^Winsys/) || ($groupname =~ m/^TMS - CAP /) ) {
      print "\n+++ for group : $groupid | $groupname+++\n";
      last if (hostgroup2_host($lauth,$groupid));
   }
}

exit(1);

