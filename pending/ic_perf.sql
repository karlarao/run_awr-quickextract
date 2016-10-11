
-- ic_perf time series
WITH
hist_ictraf AS (
SELECT /*+ &&ecr_sq_fact_hints. */
       h.instance_number,
       h.snap_id,
       SUM(CASE WHEN h.stat_name = 'gc cr blocks received'                              THEN h.value ELSE 0 END) gc_cr_bl_rx,
       SUM(CASE WHEN h.stat_name = 'gc current blocks received'                         THEN h.value ELSE 0 END) gc_cur_bl_rx,
       SUM(CASE WHEN h.stat_name = 'gc cr blocks served'                                THEN h.value ELSE 0 END) gc_cr_bl_serv,
       SUM(CASE WHEN h.stat_name = 'gc current blocks served'                           THEN h.value ELSE 0 END) gc_cur_bl_serv,
       SUM(CASE WHEN h.stat_name = 'gcs messages sent'                                  THEN h.value ELSE 0 END) gcs_msg_sent,
       SUM(CASE WHEN h.stat_name = 'ges messages sent'                                  THEN h.value ELSE 0 END) ges_msg_sent,
       SUM(CASE WHEN d.name      = 'gcs msgs received'                                  THEN d.value ELSE 0 END) gcs_msg_rcv,
       SUM(CASE WHEN d.name      = 'ges msgs received'                                  THEN d.value ELSE 0 END) ges_msg_rcv,
       SUM(CASE WHEN p.parameter_name = 'db_block_size'                                 THEN to_number(p.value) ELSE 0 END) block_size
  FROM dba_hist_sysstat h,
       dba_hist_dlm_misc d,
       dba_hist_snapshot s,
       dba_hist_parameter p
 WHERE '&&INCLUDE_IC.' = 'Y'
   AND h.snap_id >= TO_NUMBER(NVL('&&ecr_min_snap_id.','0'))
   AND h.dbid = &&ecr_dbid.
   AND h.stat_name IN ('gc cr blocks received','gc current blocks received','gc cr blocks served','gc current blocks served','gcs messages sent','ges messages sent')
   AND d.name IN ('gcs msgs received','ges msgs received')
   AND p.parameter_name = 'db_block_size'
   AND s.snap_id = h.snap_id
   AND d.snap_id = h.snap_id
   AND p.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND d.dbid = h.dbid
   AND p.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND d.instance_number = h.instance_number
   AND p.instance_number = h.instance_number
   AND CAST(s.begin_interval_time AS DATE) > SYSDATE - &&collection_days.
 GROUP BY
       h.instance_number,
       h.snap_id
),
ictraf_per_inst_and_snap_id AS (
SELECT /*+ &&ecr_sq_fact_hints. */
       h1.instance_number,
       TO_CHAR(TRUNC(CAST(s1.end_interval_time AS DATE), 'HH') + (1/24), '&&ecr_date_format.') end_time,
       (h1.gc_cr_bl_rx - h0.gc_cr_bl_rx) gc_cr_bl_rx,
       (h1.gc_cur_bl_rx - h0.gc_cur_bl_rx) gc_cur_bl_rx,
       (h1.gc_cr_bl_serv - h0.gc_cr_bl_serv) gc_cr_bl_serv,
       (h1.gc_cur_bl_serv - h0.gc_cur_bl_serv) gc_cur_bl_serv,
       (h1.gcs_msg_sent - h0.gcs_msg_sent) gcs_msg_sent,
       (h1.ges_msg_sent - h0.ges_msg_sent) ges_msg_sent,
       (h1.gcs_msg_rcv - h0.gcs_msg_rcv) gcs_msg_rcv,
       (h1.ges_msg_rcv - h0.ges_msg_rcv) ges_msg_rcv,
        h1.block_size,
       (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) * 86400 elapsed_sec
  FROM hist_ictraf h0,
       dba_hist_snapshot s0,
       hist_ictraf h1,
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
)
SELECT '&&ecr_collection_host.', '&&ecr_collection_key', 'ic_perf_ts', 'interconnect_bytes', end_time, instance_number, 0 inst_id, ROUND(MAX(((gc_cr_bl_rx + gc_cur_bl_rx + gc_cr_bl_serv + gc_cur_bl_serv)*block_size)+((gcs_msg_sent + ges_msg_sent + gcs_msg_rcv + ges_msg_rcv)*200) / elapsed_sec)) value
  FROM ictraf_per_inst_and_snap_id
 GROUP BY
       instance_number,
       end_time
 ORDER BY
       3, 4, 6, 5
/
