rem
rem  Show diff in specific statistic from AWR Data
rem  Rewritten for 10g from Statspack
rem  John Kanagaraj /Jan 2008
rem  Various modifications since
rem  This particular script is specific to the 'Estd Interconnect traffic (KB)'
rem  calculation. The formula is:
rem  Estd Interconnect traffic (KB): =(('gc cr blocks received' 
rem          + 'gc current blocks received' + 'gc cr blocks served' 
rem          + 'gc current blocks served') * Block size) 
rem          + (('gcs messages sent' + 'ges messages sent' + 'gcs msgs received'
rem           + 'gcs msgs received')*200)/1024/Elapsed Time
rem

set arraysize 5000
set termout off
set echo off verify off

set serveroutput on
set lines 300

COLUMN instance_id NEW_VALUE instance_id NOPRINT
select instance_number instance_id from v$instance;

COLUMN days_to_report NEW_VALUE days_to_report NOPRINT
select 999 days_to_report from dual;

declare 
v_total_count 		number;
v_total_count_1		number;
v_total_count_2		number;
v_total_secs_waited	number;
v_pct			number;
v_blk_size		number;
v_event_name		sys.dba_hist_system_event.event_name%TYPE;
v_wait_class		sys.dba_hist_system_event.wait_class%TYPE;
v_begin_snap_id 	sys.dba_hist_snapshot.snap_id%TYPE;
v_end_snap_id  		sys.dba_hist_snapshot.snap_id%TYPE;
v_begin_interval_time  	sys.dba_hist_snapshot.begin_interval_time%TYPE;
v_end_interval_time   	sys.dba_hist_snapshot.end_interval_time%TYPE;
v_begin_startup_time	sys.dba_hist_snapshot.startup_time%TYPE;
v_end_startup_time	sys.dba_hist_snapshot.startup_time%TYPE;
--
v_instance_number	number;  -- Change this as required
v_days_to_report        number;  -- Change this as required
--
begin_gc_cr_blk_recd number ;
begin_gc_curr_blk_recd number;
begin_gc_cr_blk_srvd number;
begin_gc_curr_blk_srvd number;
begin_gcs_msg_sent number;
begin_ges_msg_sent number;
begin_gcs_msg_rcvd number;
begin_ges_msg_rcvd number;

end_gc_cr_blk_recd number ;
end_gc_curr_blk_recd number;
end_gc_cr_blk_srvd number;
end_gc_curr_blk_srvd number;
end_gcs_msg_sent number;
end_ges_msg_sent number;
end_gcs_msg_rcvd number;
end_ges_msg_rcvd number;
--
v_stat_name	v$sysstat.name%TYPE;
v_value		v$sysstat.value%TYPE;
v_est_traffic	NUMBER;
v_est_blocks 	NUMBER;
v_est_messages 	NUMBER;
v_est_size_kb	NUMBER;
v_time_in_secs	NUMBER;


/*  This cursor fetches details of the current snapshot plus the next one
    using the LEAD function. We will use this to
    make sure that there was no DB restart inbetween */
cursor snapshot is
select lag(snap_id, 1, 0) OVER (ORDER BY snap_id) begin_snap_id, snap_id end_snap_id,
lag(to_char(startup_time), 1) OVER (ORDER BY snap_id) begin_startup_time,
to_char(startup_time) end_startup_time,
begin_interval_time, end_interval_time
from sys.dba_hist_snapshot
where instance_number = v_instance_number
and dbid = (select dbid from v$database)
and begin_interval_time > sysdate - v_days_to_report;
/* The following SQL will extract the Top 5 events based on Time waited
and considers "CPU Time" from the Sys_Time_Model as well. In that
respect, it is exactly the same as the "Top 5 Timed Events" section
in both STATSPACK and AWR. As usual, we use Analytic functions! */
cursor stat_strt is
select stat_name, value
from dba_hist_sysstat s
where s.instance_number = v_instance_number
and s.stat_name in ('gc cr blocks received','gc current blocks received','gc cr blocks served',
 'gc current blocks served', 'gcs messages sent', 'ges messages sent')
and s.snap_id = v_begin_snap_id
union
select name, value from dba_hist_dlm_misc d
where d.instance_number = v_instance_number
and name in ('ges msgs received','gcs msgs received') 
and d.snap_id = v_begin_snap_id;
cursor stat_nxt is
select stat_name, value
from dba_hist_sysstat s
where s.instance_number = v_instance_number
and s.stat_name in ('gc cr blocks received','gc current blocks received','gc cr blocks served',
 'gc current blocks served', 'gcs messages sent', 'ges messages sent')
and s.snap_id = v_end_snap_id
union
select name, value from dba_hist_dlm_misc d
where d.instance_number = v_instance_number
and name in ('ges msgs received','gcs msgs received') 
and d.snap_id = v_end_snap_id;
--
begin
v_instance_number := &instance_id;   -- Send this from command line
v_days_to_report := &days_to_report;   -- Send this from command line
-- Fetch the block size from v$parameter
select value into v_blk_size from v$parameter where name = 'db_block_size';

dbms_output.put_line('------ --------------- ----------- ----------- ----------- ----------- ----------- ----------- ----------------------- --------');
dbms_output.put_line('End    Date and Time   -        CR Blocks    - -       CURR Blocks   - -       GCS Messages  - -        GES Messages -    Estd.');
dbms_output.put_line('SnapID                 -    Served       Recd       Served        Recd        Sent        Recd        Sent        Recd  Traffic');
dbms_output.put_line('------ --------------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- --(KB)--');

open snapshot;
   LOOP
    fetch  snapshot into v_begin_snap_id, v_end_snap_id,
       v_begin_startup_time, v_end_startup_time,
       v_begin_interval_time, v_end_interval_time;
    exit when snapshot%NOTFOUND;
    -- Run through only if the startup times for both snaps are same!
    -- also, avoid the first line (lead will return 0 for begin_id)
    if ( v_begin_startup_time = v_end_startup_time ) and ( v_begin_snap_id != 0 ) then
    -- Print out Snapshot details
    open stat_strt;
    LOOP
      fetch stat_strt into v_stat_name, v_value;
        exit when stat_strt%NOTFOUND;
        if v_stat_name = 'gc cr blocks received' then  begin_gc_cr_blk_recd := v_value ;
          elsif v_stat_name = 'gc current blocks received' then begin_gc_curr_blk_recd := v_value;
          elsif v_stat_name = 'gc cr blocks served' then begin_gc_cr_blk_srvd   := v_value;
          elsif v_stat_name = 'gc current blocks served' then begin_gc_curr_blk_srvd := v_value;
          elsif v_stat_name = 'gcs messages sent' then begin_gcs_msg_sent := v_value;
          elsif v_stat_name = 'ges messages sent' then begin_ges_msg_sent := v_value;
          elsif v_stat_name = 'gcs msgs received' then begin_gcs_msg_rcvd := v_value;
          elsif v_stat_name = 'ges msgs received' then begin_ges_msg_rcvd := v_value;
          else null;
        end if; 
      end loop;
    close stat_strt;

    open stat_nxt;
    LOOP
      fetch stat_nxt into v_stat_name, v_value;
        exit when stat_nxt%NOTFOUND;
        if v_stat_name = 'gc cr blocks received' then end_gc_cr_blk_recd := v_value ;
          elsif v_stat_name = 'gc current blocks received' then end_gc_curr_blk_recd := v_value;
          elsif v_stat_name = 'gc cr blocks served' then end_gc_cr_blk_srvd := v_value;
          elsif v_stat_name = 'gc current blocks served' then end_gc_curr_blk_srvd := v_value;
          elsif v_stat_name = 'gcs messages sent' then end_gcs_msg_sent := v_value;
          elsif v_stat_name = 'ges messages sent' then end_ges_msg_sent := v_value;
          elsif v_stat_name = 'gcs msgs received' then end_gcs_msg_rcvd := v_value;
          elsif v_stat_name = 'ges msgs received' then end_ges_msg_rcvd := v_value;
          else null;
        end if; 
      end loop;
    close stat_nxt;

-- Now generate the Estd. Traffic. The formula is below
-- 'Estd Interconnect traffic (KB): =( ( 'gc cr blocks received' + 'gc current blocks received' 
-- + 'gc cr blocks served' + 'gc current blocks served') * Block size)
-- + ( ('gcs messages sent' + 'ges messages sent' + 'gcs msgs received' 
-- + 'ges msgs received')*200)/1024/Elapsed Time

v_est_blocks := nvl((end_gc_cr_blk_recd-begin_gc_cr_blk_recd),0) + nvl((end_gc_curr_blk_recd-begin_gc_curr_blk_recd),0)
               +nvl((end_gc_cr_blk_srvd-begin_gc_cr_blk_srvd),0) + nvl((end_gc_curr_blk_srvd-begin_gc_curr_blk_srvd),0);
v_est_messages := nvl((end_gcs_msg_rcvd-begin_gcs_msg_rcvd),0) + nvl((end_ges_msg_rcvd-begin_ges_msg_rcvd),0)
                 +nvl((end_gcs_msg_sent-begin_gcs_msg_sent),0) + nvl((end_ges_msg_sent-begin_ges_msg_sent),0) ;
v_est_size_kb := ((v_est_blocks * v_blk_size) + (v_est_messages * 200))/1024;
v_time_in_secs := round((to_date(to_char(v_end_interval_time,'MM/DD/YY HH24:MI:SS'),'MM/DD/YY HH24:MI:SS') - to_date(to_char(v_begin_interval_time,'MM/DD/YY HH24:MI:SS'),'MM/DD/YY HH24:MI:SS'))*24*60*60,0);
v_est_traffic := v_est_size_kb/v_time_in_secs;

        dbms_output.put_line(to_char(v_end_snap_id, '099999') 
            || ' ' || to_char(v_end_interval_time, 'MM/DD/YY HH24:MI')
            || ' ' || to_char(nvl((end_gc_cr_blk_recd-begin_gc_cr_blk_recd),0), '99,999,999')
            || ' ' || to_char(nvl((end_gc_curr_blk_recd-begin_gc_curr_blk_recd),0), '99,999,999')
            || ' ' || to_char(nvl((end_gc_cr_blk_srvd-begin_gc_cr_blk_srvd),0), '99,999,999')
            || ' ' || to_char(nvl((end_gc_curr_blk_srvd-begin_gc_curr_blk_srvd),0), '99,999,999')
            || ' ' || to_char(nvl((end_gcs_msg_rcvd-begin_gcs_msg_rcvd),0), '99,999,999')
            || ' ' || to_char(nvl((end_ges_msg_rcvd-begin_ges_msg_rcvd),0), '99,999,999')
            || ' ' || to_char(nvl((end_gcs_msg_sent-begin_gcs_msg_sent),0), '99,999,999')
            || ' ' || to_char(nvl((end_ges_msg_sent-begin_ges_msg_sent),0), '99,999,999')
            || ' ' || to_char(v_est_traffic, '999,999'));
      dbms_output.put_line('');
    end if;
   END LOOP;
close snapshot;
end;
/
set serveroutput off
