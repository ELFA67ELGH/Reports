#!/bin/ksh
#################################################
# Script Name : aedc_LD_east_mid_west_alex_ins.ksh
# Pupose      : to display hourly inst. load for Alex East Midlle West
# Modificat  By Abeer Elsayed on 7 May. 2008 
#################################################
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
rm -f  ${TMPSCC}/ld_*${usr}*
TMPSCC=/tmp/scc
id | cut -d")" -f1 | cut -d"(" -f2 | read usr
cp /dev/null  ${TMPSCC}/ld_final_${usr}.dat
mktime `date +"%Y/%m/%d:%H:%M:%S"`|read now 
mktime `date +"%Y/%m/%d:00:00:00"`|awk '{ print $1-(24*60*60)}'|read day_age

 var_asctime $now "%d/%m/%Y"  |read sugg_day
 var_asctime $day_age "%d/%m/%Y"|read sugg_day_2

read d1_f?"Please Enter From  Date   < $sugg_day_2 > : "
read d2_t?"Please Enter To   Date   < $sugg_day > : "

if [[ -z  ${d1_f} ]]
  then
    d1_f=$sugg_day_2
fi
if [[ -z ${d2_t} ]]
  then
    d2_t=$sugg_day
  fi

echo $d1_f |awk 'FS="/"{printf("%s/%s/%s:00:00:00" ,$3,$2,$1)}'|read d1  
mktime $d1 |read asc_from
echo $d2_t |awk 'FS="/"{printf("%s/%s/%s:23:59:59" ,$3,$2,$1)}'|read d2  
mktime $d2 |read asc_to

day_sec=$asc_from

if [ $asc_to -gt $now ]
then
asc_to=$now
fi
var_asctime  ${asc_from}  "%A %d/%m/%Y" |read from
var_asctime  ${asc_to}  "%A %d/%m/%Y" |read to

echo "
select rtrim(C0401_name),C0401_aid from T0401_accounts
where rtrim(C0401_name) like '%.TOTAL_MWA<INST'
go"|isql -w 100 -Udbu -Pdbudbu | grep  "[0-9]" |grep -v -e row -e C0401_aid >${TMPSCC}/ids_${usr}


cat ${TMPSCC}/ids_${usr} |grep "ALEX.TOTAL_MWA<INST"  |awk '{print $2}' |read alex_id
cat ${TMPSCC}/ids_${usr} |grep "EAST.TOTAL_MWA<INST"  |awk '{print $2}' |read east_id
cat ${TMPSCC}/ids_${usr} |grep "MIDDLE.TOTAL_MWA<INST"|awk '{print $2}' |read mid_id
cat ${TMPSCC}/ids_${usr} |grep "WEST.TOTAL_MWA<INST"  |awk '{print $2}' |read west_id

clear

echo " 
	Alexadria , East , Middle , West  load
        Max.   Mwatts  
        During	$from - $to

__________________________________________________________
	   |Time  |  East   |  Middle |   West  |    Alex |
     Day   |  hr  |  Mw     |   Mw    |   Mw    |    Mw   |
___________|______|_________|_________|_________|_________|" |tee  ${TMPSCC}/ld_final_${usr}.dat



Get_ld () {
case  "${id}"  in
 	"${east_id}" )
		DCC="East" ;;
	"${mid_id}" )
		DCC="Middle" ;;
	"${west_id}" )
		DCC="West" ;;
	"${alex_id}" )
		DCC="Alexandria"
		;;
	*)
		DCC="XXXXXXXXXXXXXXXX"
	esac


echo "
if exists(select * from T0432_data
where C0401_aid =$id  and   C0432_date between ${asc_from}  and  ${asc_to} 
and C0432_status & 8 = 8)

begin
select C0432_date,str(C0432_value_r,10,1) from T0432_data
where C0401_aid =${id}  and   C0432_date between ${asc_from}  and ${asc_to} 
and C0432_status & 8 = 8 and convert(char(8),dateadd(second,C0432_date,'${offset}'),108) like '%:00:00'
order by C0432_date
end
else
begin
print ' ${day_sec}	${day_sec}	bad_values'
end
go"|isql -Udbu -Pdbudbu |grep -v  -e rows -e C0432_date -e "\---" |grep "[0-9]" |awk '{print $1, $2}'> ${TMPSCC}/ld_${usr}_${DCC}
join -a1 -o1.1 -o2.2 -e _  ${TMPSCC}/ld_sec_${usr}  ${TMPSCC}/ld_${usr}_${DCC}|awk '{print $2}' > ${TMPSCC}/ld_${usr}_${DCC}1
}


day_sec=${asc_from}
cp /dev/null ${TMPSCC}/ld_final_${usr} 
rm -f ${TMPSCC}/ld_sec_${usr}
rm -f ${TMPSCC}/ld_hr_${usr}
 while [[ $day_sec -le  $asc_to ]]
do
echo $day_sec>>${TMPSCC}/ld_sec_${usr}
var_asctime ${day_sec} "%m/%d/%Y:%H">>${TMPSCC}/ld_hr_${usr}
day_sec=`expr $day_sec + 3600`
done

for id in  ${east_id}  ${mid_id} ${west_id} ${alex_id}
do
Get_ld
done
paste ${TMPSCC}/ld_hr_${usr}  ${TMPSCC}/ld_${usr}_East1 \
${TMPSCC}/ld_${usr}_Middle1  ${TMPSCC}/ld_${usr}_West1 \
${TMPSCC}/ld_${usr}_Alexandria1 |awk '{printf("%s/%s/%s |%5s |%8.0f |%8.0f |%8.0f |%8.0f |\n", 
substr($1,4,2),substr($1,1,2),substr($1,7,4), substr($1,12,2) , $2 ,$3 ,$4, $5)}' > ${TMPSCC}/ld_final1_${usr}
cat ${TMPSCC}/ld_final1_${usr}|sed 's/     0 /     - /g' |tee -a ${TMPSCC}/ld_final_${usr}.dat
_PRT ${TMPSCC}/ld_final_${usr}.dat
rm -f  ${TMPSCC}/ld_*${usr}* ${TMPSCC}/ids_${usr}





