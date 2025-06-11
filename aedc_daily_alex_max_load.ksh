#!/bin/ksh

. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
TMPSCC=/tmp/scc
id | cut -d")" -f1 | cut -d"(" -f2 | read usr
mktime `date +"%Y/%m/%d:%H:%M:%S"`|read now
mktime `date +"%Y/%m/%d:00:00:00"`|awk '{ print $1-35*(24*60*60)}'|read mon_ago
 var_asctime $mon_ago "%d/%m/%Y"|read sugg_day
 var_asctime $now "%d/%m/%Y"|read sugg_day_2

read from?"enter from date < ${sugg_day} > >>  "
read to?"enter to   date < ${sugg_day_2} > >>  "

if [[ -z  ${d1_f} ]]
  then
    d1_f=$sugg_day_2 
fi
if [[ -z ${d2_t} ]]
  then
    d2_t=$sugg_day
  fi
          
var_mktime ${sugg_day}    "%d/%m/%Y"  | read from_sec
var_mktime ${sugg_day_2}  "%d/%m/%Y"  | read to_sec
 

load () {

echo $acc_nm |awk 'FS="." {print $1}'|read AREA
cp /dev/null /tmp/scc/alex_load_${AREA} 
cp /dev/null /tmp/scc/alex_load_${AREA}_1
echo " select C0401_aid from T0401_accounts
where C0401_name='$acc_nm'
go"|isql -U dbu -P dbudbu |head -3 |tail -1 |read idno 

max_val=0
day_sec=$from_sec
echo "   	
	        ( $AREA ) Daily Max Load Durig 
 		 [ ${sugg_day} - ${sugg_day_2} ]
	      =====================================   

     Day	           Value		Time
			   (Mwatt)		
 ======================================================="
while [[ $day_sec -le  $to_sec ]]
do
endday=`expr $day_sec + 86400`
echo "select str(C0434_value,10,0) ,C0434_date ,C0434_time_of_occurrence from T0434_peak_data
where C0401_aid=$idno  and C0434_status & 8 = 8
and C0434_date between $day_sec and $endday order by C0434_value desc
go"|isql -U dbu -P dbudbu |grep -v -e "\----" -e C0434_time_of_occurrence  -e rows -e "^$" \
|head -1|awk '{printf("%s\n%s\n%s\n",$1,$2,$3)}'|{ read val ; read dd  ; read occ_t ; }

	if [[ ! -z $dd  && ! -z $occ_t && ! -z $val ]]
	then

if  [[ $val -gt $max_val ]]
then
max_val=$val
fi

  var_asctime  $dd  "%A %d/%m/%Y" |awk '{printf ("%-12s %-12s",$1,$2)}' |read asc_dd
	var_asctime $occ_t "%H:%M"|read asc_t
	echo "$asc_dd		$val	 	$asc_t" |tee -a /tmp/scc/alex_load_${AREA}_1
	fi
day_sec=`expr $day_sec + 86400`
done

echo "   	
	        ( $AREA ) Daily Max Load Durig 
 		 [ ${sugg_day} - ${sugg_day_2} ]
	      =====================================   

     Day	           Value		Time
			   (Mwatt)		
 =======================================================" >  /tmp/scc/alex_load_${AREA}

cat /tmp/scc/alex_load_${AREA}_1 >> /tmp/scc/alex_load_${AREA}
}

LIST="ALEX.TOTAL_MWA<HMAX EAST.TOTAL_MWA<HMAX MIDDLE.TOTAL_MWA<HMAX WEST.TOTAL_MWA<HMAX"

for acc_nm in  $LIST
do 
load
_PRT  /tmp/scc/alex_load_${AREA} 
done


