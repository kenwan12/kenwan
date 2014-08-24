#!/usr/bin/perl
#
# tm_zabbix_api.pl
#
# This is meant to be a simple wrapper to provide the basic functions to send Zabbix requests
#    and get responses with data in JASON format via HTTP POST to the Zabbix API URL
#          http://zabbix_server/zabbix/api_jsonrpc.php
#
#    The apiuser account used must have been enabled to use api
#
#    Ken Wan - 1/8/2012
#       Get authentication hash value with new_request first, then general requests
#          are served via simple_request calls
#
#    Example :
#
#    require "tm_zabbbix_api.pl";
#    api_init('localhost','admin','zabbix');   # override default server and login values,
#                                                otherwise just use   api_init();
#
#    $lauth=new_request();   # get the authentication hash
#    $lres=simple_request($lauth,'host.get','"output": "extend","select_host":"refer"');
#    $lres=simple_request($lauth,'apiinfo.version');
#

use strict;

#
#    Defaults which can be overriden via api_init
#    set to the zabbix server used first
my $url = "http://zabbix.server.com/zabbix/api_jsonrpc.php";      # Zabbix server
my $apiuser="apitest";      # API User's Username
my $apipassword="kenken";      # API User's password


#
# Get init values if any
#
sub api_init(){
my ($lurl, $user, $password) = @_;

$url = 'http://'.$lurl.'/zabbix/api_jsonrpc.php' if $lurl; # set to the zabbix server used
$apiuser=$user if $user; # API User's Username
$apipassword=$password if $password; # API User's password

}


#
# Zabbix API requests require authentication
#
sub new_request {
#my ($url, $user, $password) = @_;

my $url=$url;
my $user=$apiuser;
my $password=$apipassword;

my $authenticate = 'curl -s -i -X POST -H \'Content-Type: application/json-rpc\' -d "{
\"params\": {
\"password\": \"'.$password.'\", 
\"user\": \"'.$user.'\"
}, 
\"jsonrpc\": \"2.0\", 
\"method\": \"user.authenticate\",
\"auth\": \"\", 
\"id\": 0
}" '.$url.' | grep -Eo \'Set-Cookie: zbx_sessionid=.+\' | head -n 1 | cut -d \'=\' -f 2 | tr -d \'\r\'';
my $auth = `$authenticate`;
chomp($auth);

return $auth;

}


#
# Subroutine to issue a Zabbix API request
#
sub simple_request {
my $auth= shift;
my $command = shift;
my $params= shift;

#
# $params should be something like \"output\": \"extend\",\"name\": \"value\"
#
$params =~ s/"/\\"/g if $params;   # to add the backslashes before "s

my $process = 'curl -s -i -X POST -H \'Content-Type: application/json-rpc\' -d "{
\"jsonrpc\":\"2.0\",
\"method\":\"'.$command.'\",
\"params\":{'.$params.'},
\"auth\":\"'.$auth.'\",
\"id\": 2}" '.$url;

my $res = `$process`;
chomp($res);

return $res;

}


#
# Subroutine to issue a Zabbix API request to support the different format for Params
#
sub s_request {
my $auth= shift;
my $command = shift;
my $params= shift;

#
# $params should be something like \"output\": \"extend\",\"name\": \"value\"
#
$params =~ s/"/\\"/g if $params;   # to add the backslashes before "s

my $process = 'curl -s -i -X POST -H \'Content-Type: application/json-rpc\' -d "{
\"jsonrpc\":\"2.0\",
\"method\":\"'.$command.'\",
\"params\":[{'.$params.'}],
\"auth\":\"'.$auth.'\",
\"id\": 2}" '.$url;

my $res = `$process`;
chomp($res);

return $res;

}


########################################################################################################

1;
