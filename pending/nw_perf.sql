
-- nw_perf time series
WITH
sysstat_nwtraf AS (
SELECT /*+ 
       MATERIALIZE 
       NO_MERGE 
       FULL(h.INT$DBA_HIST_SYSSTAT.sn) 
       FULL(h.INT$DBA_HIST_SYSSTAT.s) 
       FULL(h.INT$DBA_HIST_SYSSTAT.nm) 
       USE_HASH(h.INT$DBA_HIST_SYSSTAT.sn h.INT$DBA_HIST_SYSSTAT.s h.INT$DBA_HIST_SYSSTAT.nm)
       FULL(h.sn) 
       FULL(h.s) 
       FULL(h.nm) 
       USE_HASH(h.sn h.s h.nm)
       FULL(s.INT$DBA_HIST_SNAPSHOT.WRM$_SNAPSHOT)
       FULL(s.WRM$_SNAPSHOT)
       USE_HASH(h s)
       LEADING(h.INT$DBA_HIST_SYSSTAT.nm h.INT$DBA_HIST_SYSSTAT.s h.INT$DBA_HIST_SYSSTAT.sn s.INT$DBA_HIST_SNAPSHOT.WRM$_SNAPSHOT)
       LEADING(h.nm h.s h.sn s.WRM$_SNAPSHOT)
       */
       h.instance_number,
       h.snap_id,
       SUM(CASE WHEN h.stat_name = 'bytes sent via SQL*Net to client'                   THEN h.value ELSE 0 END) tx_cl,
       SUM(CASE WHEN h.stat_name = 'bytes received via SQL*Net from client'             THEN h.value ELSE 0 END) rx_cl,
       SUM(CASE WHEN h.stat_name = 'bytes sent via SQL*Net to dblink'                   THEN h.value ELSE 0 END) tx_dl,
       SUM(CASE WHEN h.stat_name = 'bytes received via SQL*Net from dblink'             THEN h.value ELSE 0 END) rx_dl
  FROM dba_hist_sysstat h,
       dba_hist_snapshot s
 WHERE '&&INCLUDE_NETW.' = 'Y'
   AND h.snap_id >= TO_NUMBER(NVL('&&ecr_min_snap_id.','0'))
   AND h.dbid = &&ecr_dbid.
   AND h.stat_name IN ('bytes sent via SQL*Net to client','bytes received via SQL*Net from client','bytes sent via SQL*Net to dblink','bytes received via SQL*Net from dblink')
   AND s.snap_id(+) = h.snap_id
   AND s.dbid(+) = h.dbid
   AND s.instance_number(+) = h.instance_number
   AND CAST(s.begin_interval_time(+) AS DATE) > SYSDATE - &&collection_days.
 GROUP BY
       h.instance_number,
       h.snap_id
),
nwtraf_per_inst_and_snap_id AS (
SELECT /*+ 
       MATERIALIZE 
       NO_MERGE 
       FULL(s0.INT$DBA_HIST_SNAPSHOT.WRM$_SNAPSHOT)
       FULL(s0.WRM$_SNAPSHOT)
       FULL(s1.INT$DBA_HIST_SNAPSHOT.WRM$_SNAPSHOT)
       FULL(s1.WRM$_SNAPSHOT)
       USE_HASH(h0 s0 h1 s1)
       */
       h1.instance_number,
       TO_CHAR(TRUNC(CAST(s1.end_interval_time AS DATE), 'HH') + (1/24), '&&ecr_date_format.') end_time,
       (h1.tx_cl - h0.tx_cl) tx_cl,
       (h1.rx_cl - h0.rx_cl) rx_cl,
       (h1.tx_dl - h0.tx_dl) tx_dl,
       (h1.rx_dl - h0.rx_dl) rx_dl,
       (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400 elapsed_sec
  FROM sysstat_nwtraf h0,
       dba_hist_snapshot s0,
       sysstat_nwtraf h1,
       dba_hist_snapshot s1
 WHERE s0.snap_id >= TO_NUMBER(NVL('&&ecr_min_snap_id.','0'))
   AND s0.dbid = &&ecr_dbid.
   AND s0.snap_id = h0.snap_id
   AND s0.instance_number = h0.instance_number
   AND h1.instance_number = h0.instance_number
   AND h1.snap_id = h0.snap_id + 1
   AND s1.snap_id >= TO_NUMBER(NVL('&&ecr_min_snap_id.','0'))
   AND s1.dbid = &&ecr_dbid.
   AND s1.snap_id = h1.snap_id
   AND s1.instance_number = h1.instance_number
   AND s1.snap_id = s0.snap_id + 1
   AND s1.startup_time = s0.startup_time
   AND (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400 > 60 -- ignore snaps too close
)
SELECT '&&ecr_collection_host.', '&&ecr_collection_key', 'nw_perf_ts', 'nw_tx_bytes', end_time, instance_number, 0 inst_id, ROUND(MAX((tx_cl + tx_dl) / elapsed_sec)) value
  FROM nwtraf_per_inst_and_snap_id
 GROUP BY
       instance_number,
       end_time
 UNION ALL
SELECT '&&ecr_collection_host.', '&&ecr_collection_key', 'nw_perf_ts', 'nw_rx_bytes', end_time, instance_number, 0 inst_id, ROUND(MAX((rx_cl + rx_dl) / elapsed_sec)) value
  FROM nwtraf_per_inst_and_snap_id
 GROUP BY
       instance_number,
       end_time
 UNION ALL
SELECT '&&ecr_collection_host.', '&&ecr_collection_key', 'nw_perf_ts', 'nw_cl_bytes', end_time, instance_number, 0 inst_id, ROUND(MAX((tx_cl + rx_cl) / elapsed_sec)) value
  FROM nwtraf_per_inst_and_snap_id
 GROUP BY
       instance_number,
       end_time
 UNION ALL
SELECT '&&ecr_collection_host.', '&&ecr_collection_key', 'nw_perf_ts', 'nw_dl_bytes', end_time, instance_number, 0 inst_id, ROUND(MAX((tx_dl + rx_dl) / elapsed_sec)) value
  FROM nwtraf_per_inst_and_snap_id
 GROUP BY
       instance_number,
       end_time
 ORDER BY
       3, 4, 6, 5
/

