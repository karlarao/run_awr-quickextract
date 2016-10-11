-- awr_network.sql
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- NOTE: 
-- 
-- Changes: 
--		20140909: perf improvement on the script using WITH
--

set feedback off pages 50000 term off head on und off trimspool on echo off lines 4000 colsep ',' arraysize 5000 verify off

COL name NEW_V _instname NOPRINT
select lower(instance_name) name from v$instance;
COL name NEW_V _hostname NOPRINT
select lower(host_name) name from v$instance;
COL ecr_dbid NEW_V ecr_dbid;
SELECT 'get_dbid', TO_CHAR(dbid) ecr_dbid FROM v$database;
COL ecr_min_snap_id NEW_V ecr_min_snap_id;
SELECT 'get_min_snap_id', TO_CHAR(MIN(snap_id)) ecr_min_snap_id 
FROM dba_hist_snapshot WHERE dbid = &&ecr_dbid. 
and to_date(to_char(END_INTERVAL_TIME,'MM/DD/YY HH24:MI:SS'),'MM/DD/YY HH24:MI:SS') > sysdate - 100;

spool awr_network-tableau-exa-&_instname-&_hostname..csv
WITH
sysstat_io AS (
SELECT 
       instance_number,
       snap_id,
       SUM(CASE WHEN stat_name = 'cell physical IO interconnect bytes' THEN value ELSE 0 END) cellpiob
  FROM dba_hist_sysstat
 WHERE snap_id >= &&ecr_min_snap_id.
   AND dbid = &&ecr_dbid.
   AND stat_name = 'cell physical IO interconnect bytes'
 GROUP BY
       instance_number,
       snap_id
)
SELECT 
       TO_CHAR(s0.END_INTERVAL_TIME,'MM/DD/YY HH24:MI:SS') tm,
       round(((CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400)/60,2) dur,       
       s0.instance_number inst,
       ((h1.cellpiob - h0.cellpiob)/1024/1024) / ((CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400) networkmb
  FROM sysstat_io h0,
       dba_hist_snapshot s0,
       sysstat_io h1,
       dba_hist_snapshot s1
 WHERE s0.snap_id >= &&ecr_min_snap_id.
   AND s0.dbid = &&ecr_dbid.
   AND s0.snap_id = h0.snap_id
   AND s0.instance_number = h0.instance_number
   AND h1.instance_number = h0.instance_number
   AND h1.snap_id = h0.snap_id + 1
   AND s1.snap_id >= &&ecr_min_snap_id.
   AND s1.dbid = &&ecr_dbid.
   AND s1.snap_id = h1.snap_id
   AND s1.instance_number = h1.instance_number
   AND s1.snap_id = s0.snap_id + 1
   AND s1.startup_time = s0.startup_time
/
spool off
host sed -n -i '2,$ p' awr_network-tableau-exa-&_instname-&_hostname..csv
host gzip -v awr_network-tableau-exa-&_instname-&_hostname..csv
host tar -cvf awr_network-tableau-exa-&_instname-&_hostname..tar awr_network-tableau-exa-&_instname-&_hostname..csv.gz
host rm awr_network-tableau-exa-&_instname-&_hostname..csv.gz
