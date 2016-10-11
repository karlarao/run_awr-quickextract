
-- disk space usage is data,temp,controlfile,redo log,archivelog,rman backups

-- DBA_HIST_LOG DISK
WITH 
dba_hist_log_sqf AS (
SELECT /*+ 
       MATERIALIZE 
       NO_MERGE 
       FULL(h.INT$DBA_HIST_LOG.sn) 
       FULL(h.INT$DBA_HIST_LOG.log) 
       USE_HASH(h.INT$DBA_HIST_LOG.sn h.INT$DBA_HIST_LOG.log)
       FULL(h.sn) 
       FULL(h.log) 
       USE_HASH(h.sn h.log)
       */
       h.snap_id,
       h.bytes,
       h.members
  FROM dba_hist_log h
 WHERE h.snap_id >= &&escp_min_snap_id.
   AND h.dbid = &&escp_this_dbid.
),
dba_hist_snapshot_sqf AS (
SELECT /*+ 
       MATERIALIZE 
       NO_MERGE 
       FULL(s.INT$DBA_HIST_SNAPSHOT.WRM$_SNAPSHOT)
       FULL(s.WRM$_SNAPSHOT)
       */
       s.snap_id,
       s.end_interval_time
  FROM dba_hist_snapshot s
 WHERE s.snap_id >= &&escp_min_snap_id.
   AND s.dbid = &&escp_this_dbid.
   AND s.instance_number = &&escp_this_inst_num.
   AND s.end_interval_time >= SYSTIMESTAMP - &&escp_collection_days.
)
SELECT /*+ USE_HASH(h s) */
       'DISK'                            escp_metric_group,
       'LOG'                             escp_metric_acronym,
       NULL                              escp_instance_number,
       s.end_interval_time               escp_end_date,
       TO_CHAR(SUM(h.bytes * h.members)) escp_value
  FROM dba_hist_log_sqf      h,
       dba_hist_snapshot_sqf s
 WHERE s.snap_id = h.snap_id
 GROUP BY
       s.end_interval_time
 ORDER BY
       s.end_interval_time
/
