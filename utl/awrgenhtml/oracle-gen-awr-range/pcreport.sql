define num_days = 0;
define report_type = 'html'
column inst_num new_value inst_num
column dbname new_value dbname
column dbid new_value dbid
SELECT d.dbid            dbid     ,
       d.name            db_name  ,
       i.instance_number inst_num ,
       i.instance_name   inst_name
FROM   v$database d,
       v$instance i;

column begin_snap new_value begin_snap
column end_snap new_value end_snap
column report_name new_value report_name

SELECT &1 begin_snap
FROM   dual;

SELECT &2 end_snap
FROM   dual;

SELECT name
              ||'_'
              ||'&3' report_name
FROM   v$database;

@@?/rdbms/admin/awrrpti

