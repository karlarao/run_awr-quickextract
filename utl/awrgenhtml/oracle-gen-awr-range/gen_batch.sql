
--Script to Generate AWR Reports for All snap_ids Between 2 Given Dates (Doc ID 1378510.1)	
--
--EXECUTION:
--1. Save the 2 scripts as "gen_batch.sql" and "pcreport.sql"
--
--2. Execute the script "gen_batch.sql" passing BEGIN_DATE and END_DATE.
--     The date format is "DD-MON-YYYY HH24" so 9th May 2012 would need to be entered as'09-MAY-2012 00'.
--     This produces a new script called "batch.sql" which calls "pcreport.sql" once for each snapshot id range within the specified date range.
--
--         Make sure to use the right dates before an instance shutdown, as the following error may surface:
--         'ORA-20200: Begin Snapshot Id 469 does not exist for this database/instance'
--
--3. 'Execute "batch.sql"  to generate the AWR reports.


select instance_number, snap_id, TO_CHAR(end_interval_time,'DD-MON-YYYY HH24') date_hour from dba_hist_snapshot order by snap_id asc;

set echo off heading off feedback off verify off
select 'Please enter dates in DD-MON-YYYY HH24 format:' from dual;
select 'You have entered:', '&&BEGIN_DATE', '&&END_DATE' from dual;

set pages 0 termout off

spool batch.sql
SELECT DISTINCT '@pcreport '
                                ||b.snap_id
                                ||' '
                                ||e.snap_id
                                ||' '
                                || TO_CHAR(b.end_interval_time,'YYMMDD_HH24MI_')
                                ||TO_CHAR(e.end_interval_time,'HH24MI')
                                ||'.html' Commands,
                '-- '||TO_CHAR(b.end_interval_time,'YYMMDD_HH24MI') lineorder
FROM            dba_hist_snapshot b,
                dba_hist_snapshot e
WHERE           b.end_interval_time>=to_date('&BEGIN_DATE','DD-MON-YYYY HH24')
AND             b.end_interval_time<=to_date('&END_DATE','DD-MON-YYYY HH24')
AND             e.snap_id           =b.snap_id+1
ORDER BY        lineorder
/
spool off
set termout on
select 'Generating Report Script batch.sql.....' from dual;
select 'Report file created for snap_ids between:', '&&BEGIN_DATE', '&&END_DATE', 'Check file batch.sql' from dual;
set echo on termout on verify on heading on feedback on
