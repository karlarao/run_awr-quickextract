-- CDB/PDB calculated field for tableau 

alter session set container=cdb$root;

set feedback off pages 0 term off head on und off trimspool on 
set arraysize 5000
set termout off
set echo off verify off

COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

spool myash-hist-cdb-calcfield-&_instname..csv
set lines 150
select   
'ELSEIF ([Con Id])=1 and contains(lower(trim([Instname])),'''||lower(b.instance_name)||''')=true THEN str(''1'') + str(''_'') + str(''CDBROOT'') + str(''_'') + str('''||c.dbid||''')' as text
from 
v$pdbs a, v$instance b, v$database c
where a.con_id = 2
union all
select   
'ELSEIF ([Con Id])=' ||lower(a.con_id)|| ' and contains(lower(trim([Instname])),'''||lower(b.instance_name)||''')=true THEN str('''||a.con_id||''') + str(''_'') + str('''||a.name||''') + str(''_'') + str('''||a.dbid||''')' as text
from 
v$pdbs a, v$instance b;
spool off
