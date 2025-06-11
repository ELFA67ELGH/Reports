#!/bin/ksh

dba_init_file=/usr/local/sybase/dba/maint/setdbaenv.ksh
IN_FILE_DIR=/home/sis/REPORTS/MONTHLY_MAX_VALUE
/usr/local/sybase/dba/maint/setdbafct.ksh
export UN_BIN=/bin
export PTH=/aedc/data/nfs/historical
export SCC_BIN=/aedc/etc/work/aedc/SCC/bin
export SYB_DIR=/usr/local/sybase/sybase1002/bin
sybase_path="/usr/local/sybase/sybase10/interfaces"



echo "
use iutddb
go
set nocount on
select distinct 'Available months' = substring(convert(char(3) ,convert(datetime , '01-'+convert(char(2),(CSCC4_month))+'-2000',105)),1,3)+' '+ltrim(str(CSCC4_year))
from TSCC4_max_account
order by CSCC4_year , CSCC4_month
go"|isql -Udbu -Pdbudbu
read month?" Enter The Required Month in the form yyyy/mm >>>> "

      echo $month | cut -f1 -d "/" |read year
      echo $month | cut -f2 -d "/" |read mon
echo "Saving  previous data on table iutddb..TSCC4_max_account 
    to  /aedc/data/dbsave/SCC_save/SCC-tscc4.dat "
bcp iutddb..TSCC4_max_account out /aedc/data/dbsave/SCC_save/SCC-tscc4.dat -c -Usa -P tejedor
echo Saving done .....

#cp /aedc/data/dbsave/SCC_save/SCC-tscc4.dat $SCCTMP/bcp_max_account_month_org

echo  "

  BCp ${IN_FILE_DIR}/${year}_${mon}.ld into iutddb..TSCC4_max_account
"
bcp iutddb..TSCC4_max_account in ${IN_FILE_DIR}/${year}_${mon}.ld -c -t @ -Usa -P tejedor
#cat ${IN_FILE_DIR}/${year}_${mon}.ld|
#while read ln
#do
#echo $ln |awk 'FS="@" ; OFS="\n" { print $1,$2, $3,$4,$5,$6,$7,$8,$9,$10,$11}' | { read id ; read nm ; read desc ; read val ; read dd ; read ass_pnt ; read ass_val ; read max_cnt ; read mm ;
#read yy ; read rec_cnt ; read status ; read ass_status ; }

#done
                          
