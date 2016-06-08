# eSP collector for Solaris
echo "Start eSP collector."
export ORAENV_ASK=NO
 
ORATAB=/var/opt/oracle/oratab
 
db=`egrep -i ":Y|:N" $ORATAB | cut -d":" -f1 | grep -v "\#" | grep -v "\*"`
for i in $db ; do
       export ORACLE_SID=$i
       . oraenv
 

sqlplus -s /nolog <<EOF
connect / as sysdba

@sql/esp_master.sql
EOF
 
done
psrinfo -v >> cpuinfo_model_name.txt
zip -qmT esp_output.zip res_requirements_*.txt esp_requirements_*.csv cpuinfo_model_name.txt

echo "End eSP collector. Output: esp_output.zip"
