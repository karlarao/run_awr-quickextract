-- awr_netwl.sql
-- AWR Network Workload Report
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
--
-- Changes:

set arraysize 5000
set termout off
set echo off verify off

ttitle center 'AWR Network Workload Report' skip 2
set pagesize 50000
set linesize 250

col minval         format 999990.00        heading "Network|Minvalue|(mb)/s"
col maxval         format 999990.00        heading "Network|Maxvalue|(mb)/s"
col average        format 999990.00        heading "Network|Average|value|(mb)/s"
col std_dev        format 999990.00        heading "Network|Std_dev|value|(mb)/s"

select snap_id id, TO_CHAR(end_time,'MM/DD/YY HH24:MI') tm, instance_number inst, metric_name, minval/1024/1024 minval, maxval/1024/1024 maxval, average/1024/1024 average, standard_deviation/1024/1024 std_dev
from dba_hist_sysmetric_summary
where metric_name = 'Network Traffic Volume Per Sec'
-- and snap_id in (338,339)
/
