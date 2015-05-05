-- README - run_awr-quickextract
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- NOTE for customers: for sizing data gathering just execute the steps 1 and 2


------------------------------------
The scripts capture the following data sets:
------------------------------------

> Top Events - AAS CPU, latency, wait class
> SYSSTAT - Executes/sec, commits/sec, rollbacks/sec, logons/sec
> Memory - physical memory, PGA, SGA
> IO - IOPS breakdown, MB/s
> CPU - Load Average, NUM_CPUs, 
> Storage - total storage size, per tablespace size
> Services - distribution of workload/modules
> Top SQL - PIOs, LIOs, modules, SQL type, SQL_ID, PX


------------------------------------
STEP 1: COLLECT AWR DATA 
------------------------------------

Unzip the scripts under /home/oracle/dba/run_awr-quickextract

There are four ways to run the data collection but the end result will all be CSV files which will be consolidated on STEP 2:

  1a) on the server, as SYSDBA run the run_all.sql on each database

  1b) on the server, as Oracle user execute the run_awr on the first node of the cluster, but if you have 
	a spread out node layout across nodes then better to do the run_all.sql on each DB or step 1c below

  1c) on a linux machine or OEM server, do the following
       - edit the tnsnames.ora and add the TNS entries of all the databases
       - edit the dblist file with the format <tns entry>,<username>,<password>
       - check the run_awr_tns file, make sure the TNS_ADMIN and ORACLE_HOME are correct
       - run the test_run_awr_tns to check if you can login on all the databases
           there should be no entries under "Fix TNS or dblist entry below:" section, otherwise fix it
       - run the run_awr_tns 
       - consolidate the tar files

  1d) if you only have a windows environment to run the scripts do the following:
       - for each DB run on the command prompt sqlplus <username>/<password>@<tns> @run_all
       - you can create a windows batch file (.bat) to execute the above command on all DBs 


------------------------------------
STEP 2: CONSOLIDATE TAR FILES 
------------------------------------

After running the scripts consolidate all TAR files in one zip file. 

mkdir csvfiles_$HOSTNAME
mv *tar csvfiles_$HOSTNAME/
zip -r csvfiles_$HOSTNAME.zip csvfiles_$HOSTNAME


------------------------------------
STEP 3: EXTRACT & PACKAGE CSV FILES
------------------------------------

- This section should be done on your laptop or another server 
- The packaged CSV files are the files used for sizing and workload characterization

3a) Put all ZIP files in one folder, then extract the CSV files with the following commands:

mkdir tarfiles
for i in *.zip; do unzip $i -d tarfiles; done
find tarfiles -name '*.tar' | while read file; do mv "$file" "tarfiles/$(tr / _ <<< "$file")" ; done
cd tarfiles
for i in *.tar; do tar xf $i; echo $i; done
gunzip -vf *.gz


3b) Package all CSV files 

find . -name '*awr_topevents*.csv' | while read file; do
cat "$file" >> awr_topevents.txt
done
find . -name '*awr_sysstat*.csv' | while read file; do
cat "$file" >> awr_sysstat.txt
done
find . -name '*awr_sgapga*.csv' | while read file; do
cat "$file" >> awr_sgapga.txt
done
find . -name '*awr_cpuwl*.csv' | while read file; do
cat "$file" >> awr_cpuwl.txt
done
find . -name '*awr_iowl*.csv' | while read file; do
cat "$file" >> awr_iowl.txt
done
find . -name '*awr_storagesize_summary*.csv' | while read file; do
cat "$file" >> awr_storagesize_summary.txt
done
find . -name '*awr_storagesize_detail*.csv' | while read file; do
cat "$file" >> awr_storagesize_detail.txt
done
find . -name '*awr_storagesize_rman*.csv' | while read file; do
cat "$file" >> awr_storagesize_rman.txt
done
find . -name '*awr_services*.csv' | while read file; do
cat "$file" >> awr_services.txt
done
find . -name '*awr_topsqlx*.csv' | while read file; do
cat "$file" >> awr_topsqlx.txt
done
find . -name '*awr_topsegments*.csv' | while read file; do
cat "$file" >> awr_topsegments.txt
done

tar -cjvpf awrcsvfiles.tar.bz2 *txt





