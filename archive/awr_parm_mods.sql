-- parm_mods.sql
--
-- Shows all parameters (including hidden) that have been modified.
-- Uses the lag function so that a single record is returned for each change.
-- It uses AWR data - so only snapshots still in the database will be included.
--
-- The script prompts for a parameter name (which can be wild carded).
-- Leaving the parameter name blank matches any parameter (i.e. it will show all changes).
-- Calculated hidden parameters (those that start with two underscores like "__shared_pool_size")
-- will not be displayed unless requested with a Y.
--
-- Kerry Osborne
--
-- Note: I got this idea from Jeff White.
--

set arraysize 5000
set termout off
set echo off verify off

set linesize 155
col time for a15
col parameter_name format a50
col old_value format a30
col new_value format a30
break on instance skip 3
select instance_number instance, snap_id, time, parameter_name, old_value, new_value from (
select a.snap_id,to_char(end_interval_time,'MM/DD/YY HH24:MI') TIME,  a.instance_number, parameter_name, value new_value,
lag(parameter_name,1) over (partition by parameter_name, a.instance_number order by a.snap_id) old_pname,
lag(value,1) over (partition by parameter_name, a.instance_number  order by a.snap_id) old_value ,
decode(substr(parameter_name,1,2),'__',2,1) calc_flag
from dba_hist_parameter a, dba_Hist_snapshot b , v$instance v
where a.snap_id=b.snap_id
and a.instance_number=b.instance_number
and parameter_name like (parameter_name)
and a.instance_number like (v.instance_number)
)
where
new_value != old_value
and calc_flag not in (decode('Y','Y',3,2))
order by 1,2
/
