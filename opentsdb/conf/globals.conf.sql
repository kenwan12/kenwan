#
# category loop_time collection listset instance(s) template tag1=value1 ...
# default is the default collection
#
s|30|default|processor|*|default.processor.tt|
s|30|default|physicaldisk|*|default.disk.tt|
s|30|default|logicaldisk|*|default.logicaldisk.tt|
s|30|default|memory||default.memory.tt|
n|30|default|network interface|*,^isaptap|default.lan.tt|
s|30|default|system||default.system.tt|
s|30|default|tcpv4||default.tcpv4.tt|
# sql
s|30|default|SQLServer:Buffer Manager||default.sqlbm.tt|
s|30|default|SQLServer:General Statistics||default.sqlgs.tt|
s|30|default|SQLServer:Memory Manager||default.sqlmm.tt|
s|30|default|SQLServer:SQL Statistics||default.sqlss.tt|
# External Scripts
#e|30|default|w3wp_metrics.ps1|
# END