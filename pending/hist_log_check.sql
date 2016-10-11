
21:07:29 SYS@cdb1> show parameter log_archive_start

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
log_archive_start                    boolean     FALSE


21:10:26 SYS@cdb1> startup mount
ORACLE instance started.

Total System Global Area  734003200 bytes
Fixed Size                  2928728 bytes
Variable Size             633343912 bytes
Database Buffers           92274688 bytes
Redo Buffers                5455872 bytes
Database mounted.
21:10:40 SYS@cdb1>
21:10:56 SYS@cdb1>
21:10:57 SYS@cdb1> alter database archivelog;

Database altered.

21:11:02 SYS@cdb1> archive log list
Database log mode              Archive Mode
Automatic archival             Enabled
Archive destination            USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     656
Next log sequence to archive   658
Current log sequence           658
21:11:11 SYS@cdb1> alter database open
21:11:17   2  ;

Database altered.

21:11:24 SYS@cdb1> show parameter log_archive_start

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
log_archive_start                    boolean     FALSE


21:17:27 SYS@cdb1> 

  1  select snap_id, archived from dba_hist_log
  2* order by snap_id asc

   SNAP_ID ARC
---------- ---
      2785 NO
      2785 NO

... output snipped ... 

      2919 NO
      2919 NO
      2919 NO

405 rows selected.


21:18:22 SYS@cdb1> exec dbms_workload_repository.create_snapshot;

PL/SQL procedure successfully completed.

21:18:36 SYS@cdb1> select snap_id, archived from dba_hist_log order by snap_id asc;

   SNAP_ID ARC
---------- ---
      2785 NO
      2785 NO

... output snipped ... 

      2920 NO
      2920 YES

   SNAP_ID ARC
---------- ---
      2920 YES

408 rows selected.





