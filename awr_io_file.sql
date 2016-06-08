-- awr_io_file.sql
-- AWR File IO Report, across SNAP_IDs
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- 

set arraysize 5000
set termout off
set echo off verify off

COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v$database;

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v$instance;

ttitle center 'AWR File IO Report' skip 2
set pagesize 50000
set linesize 250


col snap_id     format 99999            heading "Snap|ID"
col tm          format a15              heading "Snap|Start|Time"
col inst        format 90               heading "i|n|s|t|#"
col dur         format 999990.00        heading "Snap|Dur|(m)"
col tsname      format a20              heading "TS"
col file#       format 9990             heading "File#"
col filename    format a60              heading "Filename"
col io_rank     format 90               heading "IO|Rank"
col readtim     format 9999999          heading "Read|Time"
col reads       format 9999999          heading "Reads"
col atpr        format 99990.0          heading "Av|Rd(ms)"
col rps         format 9999999          heading "IOPS|Av|Reads/s"
col bpr         format 99990.0          heading "Av|Blks/Rd"
col writetim    format 9999999          heading "Write|Time"
col writes      format 9999999          heading "Writes"
col atpw        format 99990.0          heading "Av|Wt(ms)"
col wps         format 9999999          heading "IOPS|Av|Writes/s"
col bpw         format 99990.0          heading "Av|Blks/Wrt"
col waits       format 9999999          heading "Buffer|Waits"
col atpwt       format 99990.0          heading "Av Buf|Wt(ms)"
col ios         format 9999999          heading "Total|IO R+W"
col iops        format 9999999          heading "IOPS|Total|R+W"

select snap_id, TO_CHAR(tm,'MM/DD/YY HH24:MI') tm, inst, dur, tsname, file#, filename, io_rank, readtim, reads, atpr, rps, bpr, writetim, writes, atpw, wps, bpw, waits, atpwt, ios, iops
from 
      (select snap_id, tm, inst, dur, tsname, file#, filename, readtim, reads, atpr, rps, bpr, writetim, writes, atpw, wps, bpw, waits, atpwt, ios, iops,
            DENSE_RANK() OVER (
          PARTITION BY snap_id ORDER BY ios DESC) io_rank
      from 
              (
                select 
                                      s0.snap_id snap_id,
                                      s0.END_INTERVAL_TIME tm,
                                      s0.instance_number inst,
                                      round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                        e.tsname,
                                        e.file#
                                      , substr(e.filename, 1, 52)                       filename
                                      , e.readtim  - nvl(b.readtim,0)                    readtim
                                      , e.phyrds - nvl(b.phyrds,0)                       reads
                                      , decode ((e.phyrds - nvl(b.phyrds, 0)), 0, to_number(NULL), ((e.readtim  - nvl(b.readtim,0)) / (e.phyrds   - nvl(b.phyrds,0)))*10)         atpr
                                      , (e.phyrds - nvl(b.phyrds,0)) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) rps      -- ela
                                      , decode ((e.phyrds - nvl(b.phyrds, 0)), 0, to_number(NULL), (e.phyblkrd - nvl(b.phyblkrd,0)) / (e.phyrds   - nvl(b.phyrds,0)) )             bpr
                                      , e.writetim  - nvl(b.writetim,0)                 writetim
                                      , e.phywrts - nvl(b.phywrts,0)                    writes
                                      , decode ((e.phywrts - nvl(b.phywrts, 0)), 0, to_number(NULL), ((e.writetim  - nvl(b.writetim,0)) / (e.phywrts   - nvl(b.phywrts,0)))*10)         atpw
                                      , (e.phywrts - nvl(b.phywrts,0)) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) wps      -- ela
                                      , decode ((e.phywrts - nvl(b.phywrts, 0)), 0, to_number(NULL), (e.phyblkwrt - nvl(b.phyblkwrt,0)) / (e.phywrts   - nvl(b.phywrts,0)) )             bpw
                                      , e.wait_count - nvl(b.wait_count,0)              waits
                                      , decode ((e.wait_count - nvl(b.wait_count, 0)), 0, 0, ((e.time - nvl(b.time,0)) / (e.wait_count - nvl(b.wait_count,0)))*10)   atpwt,
                                    (e.phyrds  - nvl(b.phyrds,0)) + (e.phywrts - nvl(b.phywrts,0))                     ios,
                                    ((e.phyrds  - nvl(b.phyrds,0)) + (e.phywrts - nvl(b.phywrts,0))) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) iops     
                   from 
                        dba_hist_snapshot s0,
                        dba_hist_snapshot s1,
                        dba_hist_filestatxs e,
                        dba_hist_filestatxs b
                    where 
                                    s0.dbid                   = &_dbid            -- CHANGE THE DBID HERE!
                                    AND s1.dbid               = s0.dbid  
                                    and b.dbid(+)             = s0.dbid                               -- begin dbid
                                    and e.dbid                = s0.dbid                               -- end dbid
                                    and b.dbid            = e.dbid -- remove oj 
                                    AND s0.instance_number    = &_instancenumber  -- CHANGE THE INSTANCE_NUMBER HERE!
                                    AND s1.instance_number    = s0.instance_number
                                    and b.instance_number(+) = s0.instance_number                                        -- begin instance_num
                                    and e.instance_number    = s0.instance_number                                        -- end instance_num
                                    and b.instance_number = e.instance_number -- remove oj
                                    AND s1.snap_id            = s0.snap_id + 1
                                    and b.snap_id(+)         = s0.snap_id                                      -- begin snap_id
                                    and e.snap_id            = s0.snap_id + 1                                      -- end snap_id
                      and b.tsname          = e.tsname -- remove oj
                      and b.file#           = e.file# -- remove oj
                      and b.creation_change# = e.creation_change# -- remove oj
                      and ((e.phyrds  - nvl(b.phyrds,0))  + 
                           (e.phywrts - nvl(b.phywrts,0))) > 0
            union all
                 select 
                                      s0.snap_id snap_id,
                                      s0.END_INTERVAL_TIME tm,
                                      s0.instance_number inst,
                                      round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                        e.tsname,
                                        e.file#
                                      , substr(e.filename, 1, 52)                       filename
                                      , e.readtim  - nvl(b.readtim,0)                    readtim
                                      , e.phyrds- nvl(b.phyrds,0)                       reads
                                      , decode ((e.phyrds - nvl(b.phyrds, 0)), 0, to_number(NULL), ((e.readtim  - nvl(b.readtim,0)) / (e.phyrds   - nvl(b.phyrds,0)))*10)         atpr
                                      , (e.phyrds- nvl(b.phyrds,0)) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) rps       -- ela
                                      , decode ((e.phyrds - nvl(b.phyrds, 0)), 0, to_number(NULL), (e.phyblkrd - nvl(b.phyblkrd,0)) / (e.phyrds   - nvl(b.phyrds,0)) )             bpr
                                      , e.writetim  - nvl(b.writetim,0)                 writetim
                                      , e.phywrts - nvl(b.phywrts,0)                    writes
                                      , decode ((e.phywrts - nvl(b.phywrts, 0)), 0, to_number(NULL), ((e.writetim  - nvl(b.writetim,0)) / (e.phywrts   - nvl(b.phywrts,0)))*10)         atpw
                                      , (e.phywrts - nvl(b.phywrts,0)) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) wps        -- ela
                                      , decode ((e.phywrts - nvl(b.phywrts, 0)), 0, to_number(NULL), (e.phyblkwrt - nvl(b.phyblkwrt,0)) / (e.phywrts   - nvl(b.phywrts,0)) )             bpw
                                      , e.wait_count - nvl(b.wait_count,0)              waits
                                      , decode ((e.wait_count - nvl(b.wait_count, 0)), 0, to_number(NULL), ((e.time       - nvl(b.time,0)) / (e.wait_count - nvl(b.wait_count,0)))*10)   atpwt, 
                                    (e.phyrds  - nvl(b.phyrds,0)) + (e.phywrts - nvl(b.phywrts,0))                     ios,
                                    ((e.phyrds  - nvl(b.phyrds,0)) + (e.phywrts - nvl(b.phywrts,0))) / 
                                            ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) iops    
                   from
                        dba_hist_snapshot s0,
                        dba_hist_snapshot s1,
                        dba_hist_tempstatxs e,
                        dba_hist_tempstatxs b
                    where 
                                    s0.dbid                   = &_dbid            -- CHANGE THE DBID HERE!
                                    AND s1.dbid               = s0.dbid  
                                    and b.dbid(+)             = s0.dbid                               -- begin dbid
                                    and e.dbid                = s0.dbid                               -- end dbid
                                    and b.dbid            = e.dbid -- remove oj 
                                    AND s0.instance_number    = &_instancenumber  -- CHANGE THE INSTANCE_NUMBER HERE!
                                    AND s1.instance_number    = s0.instance_number
                                    and b.instance_number(+) = s0.instance_number                                        -- begin instance_num
                                    and e.instance_number    = s0.instance_number                                        -- end instance_num
                                    and b.instance_number = e.instance_number -- remove oj
                                    AND s1.snap_id            = s0.snap_id + 1
                                    and b.snap_id(+)         = s0.snap_id                                      -- begin snap_id
                                    and e.snap_id            = s0.snap_id + 1                                      -- end snap_id
                      and b.tsname          = e.tsname -- remove oj
                      and b.file#           = e.file# -- remove oj
                      and b.creation_change# = e.creation_change# -- remove oj
                      and ((e.phyrds  - nvl(b.phyrds,0))  + 
                           (e.phywrts - nvl(b.phywrts,0))) > 0 
              )
      )
-- where 
-- atpr > 10
-- io_rank <= 3
-- AND TO_CHAR(tm,'D') >= 1     -- Day of week: 1=Sunday 7=Saturday
-- AND TO_CHAR(tm,'D') <= 7
-- AND TO_CHAR(tm,'HH24MI') >= 0900     -- Hour
-- AND TO_CHAR(tm,'HH24MI') <= 1800
-- AND tm >= TO_DATE('2010-jan-17 00:00:00','yyyy-mon-dd hh24:mi:ss')     -- Data range
-- AND tm <= TO_DATE('2010-aug-22 23:59:59','yyyy-mon-dd hh24:mi:ss')
-- snap_id = 338
-- where snap_id in (338,339,578)
;