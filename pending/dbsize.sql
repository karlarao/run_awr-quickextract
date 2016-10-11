
$ du -sm * | sort -rnk1
911     sysaux01.dbf
701     system01.dbf
301     undotbs01.dbf
52      temp02.dbf
51      redo03.log
51      redo02.log
51      redo01.log
10      control01.ctl
9       users01.dbf
oracle@karldevfedora:/u01/app/oracle/oradata/cdb1:cdb1
$ du -sm
2130    .


-- 2187.875
select 
( select sum(bytes)/1024/1024 data_size from dba_data_files ) +
( select nvl(sum(bytes),0)/1024/1024 temp_size from dba_temp_files ) +
( select sum(bytes)/1024/1024 redo_size from sys.v_$log ) +
( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024 controlfile_size from v$controlfile) "Size in GB"
from
dual
/

-- 2187.875
SELECT a.data_size + b.temp_size + c.redo_size + d.controlfile_size 
"total_size in GB" 
FROM (SELECT SUM (bytes) / 1024 / 1024 data_size FROM dba_data_files) a, 
(SELECT NVL (SUM (bytes), 0) / 1024 / 1024 temp_size 
FROM dba_temp_files) b, 
(SELECT SUM (bytes) / 1024 / 1024 redo_size FROM sys.v_$log) c, 
(SELECT SUM (BLOCK_SIZE * FILE_SIZE_BLKS) / 1024 / 1024 
controlfile_size 
FROM v$controlfile) d
/

-- Database Size        Used space           Free space
-- -------------------- -------------------- --------------------
-- 2169 MB              1640 MB              529 MB
col "Database Size" format a20
col "Free space" format a20
col "Used space" format a20
select round(sum(used.bytes) / 1024 / 1024  ) || ' MB' "Database Size"
, round(sum(used.bytes) / 1024 / 1024  ) - 
round(free.p / 1024 / 1024 ) || ' MB' "Used space"
, round(free.p / 1024 / 1024 ) || ' MB' "Free space"
from (select bytes
from v$datafile
union all
select bytes
from v$tempfile
union all
select bytes
from v$log) used
, (select sum(bytes) as p
from dba_free_space) free
group by free.p
/

