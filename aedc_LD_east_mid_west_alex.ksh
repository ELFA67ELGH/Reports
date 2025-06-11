#!/bin/ksh
#################################################
# Script Name : aedc_LD_east_mid_west_alex.ksh
# Pupose      : to display hourly load for Alex East Midlle West
# Modificat  By Abeer Elsayed on 4 Nov. 2006 
#################################################
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions


TMPSCC=/tmp/scc/`id -u -n`
createDir ${TMPSCC}

id | cut -d")" -f1 | cut -d"(" -f2 | read usr

Get_ld () {
frst_yr=${offset}
case  "${id}"  in
 	"${east_id}" )
		DCC="East" ;;
	"${mid_id}" )
		DCC="Middle" ;;
	"${west_id}" )
		DCC="West" ;;
	"${alex_id}" )
		DCC="Alexandria"

case ${acc_tp} in
HMAX)
echo "select C0434_date,convert(char(5),dateadd(second,C0434_time_of_occurrence ,'${offset}'),108) from T0434_peak_data where C0401_aid =${id}  and  
C0434_date between ${asc_from} and ${asc_to} and C0434_status & 8 = 8 order by C0434_date
go"|isql -Udbu -Pdbudbu |grep -v  -e rows -e C0434_date -e "\---" |grep "[0-9]" |
awk '{print $1 , $2}'> ${TMPSCC}/dt_${usr}_${DCC}
;;
INST)
echo "select C0432_date,convert(char(5),dateadd(second,C0432_date ,'${offset}'),108) from T0432_data where C0401_aid =${id}  and  
C0432_date between ${asc_from} and ${asc_to} and C0432_status & 8 = 8 order by C0432_date
go"|isql -Udbu -Pdbudbu |grep -v  -e rows -e C0432_date -e "\---" |grep "[0-9]" |
awk '{print $1 , $2}'> ${TMPSCC}/dt_${usr}_${DCC}

;;
esac
join -a1 -o2.2 -e _  ${TMPSCC}/ld_sec_${usr}  ${TMPSCC}/dt_${usr}_${DCC} > ${TMPSCC}/dt_${usr}_${DCC}1
         ;;
	*)
		DCC="XXXXXXXXXXXXXXXX"
	esac

echo "
if exists(select * from ${tb_nm}
where C0401_aid =$id  and   C${tb_nom}_date between ${asc_from}  and  ${asc_to} 
and C${tb_nom}_status & 8 = 8)

begin
select C${tb_nom}_date,str(C${tb_nom}_value${val_nm},10,1) from ${tb_nm}
where C0401_aid =${id}  and   C${tb_nom}_date between ${asc_from}  and ${asc_to} 
and C${tb_nom}_status & 8 = 8
order by C${tb_nom}_date
end
else
begin
print ' ${day_sec}	${day_sec}	bad_values'
end
go"|isql -Udbu -Pdbudbu |grep -v  -e rows -e C${tb_nom}_date -e "\---" |
    grep "[0-9]" |awk '{print $1, $2}'> ${TMPSCC}/ld_${usr}_${DCC}
    
    
join -a1 -o2.2 -e _  ${TMPSCC}/ld_sec_${usr} ${TMPSCC}/ld_${usr}_${DCC} > ${TMPSCC}/ld_${usr}_${DCC}1
}

Report() {
echo "
select rtrim(C0401_name),C0401_aid from T0401_accounts where rtrim(C0401_name) like '%.${suff}<${acc_tp}'
go"|isql -w 100 -Udbu -Pdbudbu | grep  "[0-9]" |grep -v -e row -e C0401_aid >${TMPSCC}/ids_${usr}
cat ${TMPSCC}/ids_${usr} |grep "ALEX.${suff}<${acc_tp}"  |awk '{print $2}' |read alex_id
cat ${TMPSCC}/ids_${usr} |grep "EAST.${suff}<${acc_tp}"  |awk '{print $2}' |read east_id
cat ${TMPSCC}/ids_${usr} |grep "MIDDLE.${suff}<${acc_tp}"|awk '{print $2}' |read mid_id
cat ${TMPSCC}/ids_${usr} |grep "WEST.${suff}<${acc_tp}"  |awk '{print $2}' |read west_id

#clear

echo " 
	[ Alexadria , East , Middle , West ]   
        ${titl} Mwatts  Load Report
        	$from $to_statmnt  ( From ${REP} )
______________________________________________________
	   |Time|      |      |	     |       |Alex.Tm|
     Day   | hr |  East|Middle|West  |  Alex | hh:mm | 
___________|____|______|______|______|_______|_______|" |tee  ${TMPSCC}/ld_final_${usr}.dat

day_sec=${asc_from}
cp /dev/null ${TMPSCC}/ld_final_${usr} 

 while [[ $day_sec -le  $asc_to ]]
do
echo $day_sec >>${TMPSCC}/ld_sec_${usr}
var_asctime $day_sec "%m/%d/%Y:%H">>${TMPSCC}/ld_hr_${usr}
day_sec=`expr $day_sec + ${per_sec}`
done
Get_ld

for id in  ${east_id}  ${mid_id}  ${west_id}  ${alex_id}
do
Get_ld
done

paste ${TMPSCC}/ld_hr_${usr}  ${TMPSCC}/ld_${usr}_East1 \
${TMPSCC}/ld_${usr}_Middle1  ${TMPSCC}/ld_${usr}_West1 \
${TMPSCC}/ld_${usr}_Alexandria1 ${TMPSCC}/dt_${usr}_Alexandria1|awk '{alex=$5
{if (substr($1,12,2)> 0 )
{if(alex>Max && alex != "_" )
{Max=alex ; east=$2 ; mid=$3 ; west=$4 ;DD=$1;AD=$6}}
{printf("%s/%s/%s | %2s |%5.0f |%5.0f |%5.0f |%6.0f | %5s |\n",
substr($1,4,2),substr($1,1,2),substr($1,7,4),substr($1,12,2) , $2 ,$3 ,$4, $5, $6)}}}
END{{print "___________|____|______|______|______|_______|_______|"}
{printf("Max                                  |       |       |\n%s/%s/%s | %2s |%5.0f |%5.0f |%5.0f |%6.0f | %5s |\n", 
substr(DD,4,2),substr(DD,1,2),substr(DD,7,4),substr(DD,12,2)  , east  ,  mid   ,  west  ,  Max, substr(AD,1,5))}
{print "___________|____|______|______|______|_______|_______|"}}'> ${TMPSCC}/ld_final1_${usr}
cat ${TMPSCC}/ld_final1_${usr}|sed 's/  0 /  - /g' |tee -a ${TMPSCC}/ld_final_${usr}.dat
}

function sammary {
 head -4 ${TMPSCC}/ld_final_${usr}.dat |
     tail -2 | sed "s/Hourly/$SamOutFl Hourly/" |
     sed "s/LdFinal//" > ${TMPSCC}/$SamOutFl
 echo "
 _______________________________
           |Time|      |Alex.Tm
     Day   | hr |  MW  | hh:mm 
___________|____|______|_______ " >> ${TMPSCC}/$SamOutFl

grep -v -e [a-z] -e "____"  ${TMPSCC}/ld_final_${usr}.dat  | 
     awk '{print $1}' | grep -v "^$" | sort -u -t"/" -k3 -k2 -k1|
     while read dt
     do
     grep "^${dt}" ${TMPSCC}/ld_final_${usr}.dat | sort -n -t "|" -k${fild} | tail -1 |
         awk -v f=${fild} 'FS="|",OFS="|"{print $1,$2,$f,$7}' >> ${TMPSCC}/$SamOutFl
     
     done
cat ${TMPSCC}/$SamOutFl
_PRT ${TMPSCC}/$SamOutFl
     
}
#===========================
# 	Start Point 
#===========================
rm -f  ${TMPSCC}/ld_*${usr}* ${TMPSCC}/ids_${usr}
cp /dev/null  ${TMPSCC}/ld_final_${usr}.dat


mktime `date +"%Y/%m/%d:%H:%M:%S"`|read now 
mktime `date +"%Y/%m/%d:00:00:00"`|read today 
mktime `date +"%Y/%m/%d:01:00:00"`|awk '{ print $1-(24*60*60)}'|read day_age

var_asctime ${now}  "%d/%m/%Y"  |read sugg_day
var_asctime $day_age "%d/%m/%Y"|read sugg_day_2

clear


 echo " 
             Alexadria  & East , Middle , West
                    Hourly Max Load Report  
        ================================================
"
read d1_t?"Please Enter From  Date   < ${sugg_day_2} > : "
read d2_t?"Please Enter To    Date   < ${sugg_day} > : "

if [[ -z  ${d1_t} ]]
  then
    d1_t=${sugg_day_2}
fi
if [[ -z ${d2_t} ]]
  then
    d2_t=${sugg_day}
  fi

echo ${d1_t} |awk 'FS="/"{printf("%s/%s/%s:01:00:00" ,$3,$2,$1)}'|read d1  
mktime $d1 |read asc_from
echo ${d2_t} |awk 'FS="/"{printf("%s/%s/%s:23:59:59" ,$3,$2,$1)}'|read d2  
mktime $d2 |awk '{print $1+1}'|read asc_to

day_sec=$asc_from

if [ ${asc_to} -gt ${now} ]
then
asc_to=${now}
fi
var_asctime  ${asc_from}  "%A %d/%m/%Y" |read from
var_asctime  ${asc_to}  "%A %d/%m/%Y" |read to
   if [ "$d1_t" = "$d2_t" ]
   then
   to_statmnt=""
   else
   to_statmnt="- $to"
   fi

read ans?"
        Report Form :


              1) MWatt ( From Amp )

              2) Inst. Mwatt ( From Amp )
	      
	      3) report estimated east
	      

Enter Ur Selection    : "



if [[ -z ${ans} ]]
 then
ans="1"
fi

case ${ans} in
1) suff="TOTAL_MWA" 
   acc_tp="HMAX" 
   REP=Amp  
   titl="Hourly Max." 
   per_sec=3600 
   tb_nm=T0434_peak_data 
   tb_nom=0434 
   val_nm="" 
   Report
   ;;
2) suff="TOTAL_MWA" 
   acc_tp="INST" 
   REP=Amp  
   titl="Instantinus" 
   per_sec=900  
   tb_nm=T0432_data      
   tb_nom=0432 
   val_nm="_r" 
   Report
   ;;
3) 
echo "Preparing estimatd values for East, Alex guided by previous data (52 week ago) 

Do you want to use other day as a guide?"
read offset52?"Enter offset:
    if you want to change enter a value as [ ... -2 -1 1 2 ...]
    if not enter [ 0 or <CR> ]
				>> "
if [ -z "$offset52" ]
then
offset52=0
fi


echo " 
	[ Alexadria , East , Middle , West ]   
        ${titl} Mwatts  Load Report
        	$from $to_statmnt  ( From ${REP} )
______________________________________________________
	   |Time|      |      |	     |       |Alex.Tm|
     Day   | hr |  East|Middle|West  |  Alex | hh:mm | 
___________|____|______|______|______|_______|_______|" |tee  ${TMPSCC}/ld_final_${usr}.dat

mktime `var_asctime $asc_from %Y/%m/%d:00:00:00` |read start_dt_sec
#if [ ${asc_to} -gt ${today} ]
#then
#asc_to=${today}
#fi
#mktime `var_asctime $asc_to %Y/%m/%d:00:00:00` |read end_dt_sec
mktime ${d2}:00:00:00 | read end_dt_sec

dt_sec=$start_dt_sec
print -n "" > ${TMPSCC}/ld_final1_${usr}
while [[ $dt_sec -lt  $end_dt_sec ]]
do
  echo "working with $dt_sec"
  var_asctime $dt_sec "%Y/%m/%d" | read d_thisYr
  expr $dt_sec - 52 \* 7 \* 24 \* 60 \* 60 + $offset52 \* 86400 | read week52ago_sec
  var_asctime $week52ago_sec "%Y/%m/%d" |read d_lastYr
echo "Report will be guided by $d_lastYr"

  Percent_hr_DCC_LD.ksh $d_thisYr
  cp  ${TMPSCC}/final.xls   ${TMPSCC}/this
  Percent_hr_DCC_LD.ksh $d_lastYr
  cp   ${TMPSCC}/final.xls   ${TMPSCC}/last

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#    if [ "`wc -l /tmp/this|awk '{print $1}'`" = "`wc -l /tmp/last|awk '{print $1}'`" ]
#    then
#    paste ${TMPSCC}/this ${TMPSCC}/last |
#       awk '{print $2,substr($3,1,2),($6+$7)*0.01*$18/(1-0.01*$18),$6,$7,($6+$7)/(1-0.01*$18),substr($3,1,5)}'|
#       awk '{printf("%s | %s | %d | %d | %d | %d | %s |\n",$1,$2,$3,$4,$5,$6,$7)}'>>${TMPSCC}/ld_final1_${usr}
#    else
#    echo "Error : unmatched data between $d_thisYr and $d_lastYr
#    ... call SW staff
#hint for SW staff : run : dxdiff ${TMPSCC}/this ${TMPSCC}/last "
#    echo "$d_thisYr | XX | --- | --- | --- | ---- | XX:00 |" >>  ${TMPSCC}/ld_final1_${usr}
#    fi
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
print -n "" >  ${TMPSCC}/filteredThis
print -n "" >  ${TMPSCC}/filteredLast

for hr in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23
 do
 if [ ! -z "`grep ${hr}:00:00  ${TMPSCC}/this`" ] && [ ! -z "`grep ${hr}:00:00  ${TMPSCC}/last`" ]
 then
 grep ${hr}:00:00  ${TMPSCC}/this >>  ${TMPSCC}/filteredThis
 grep ${hr}:00:00  ${TMPSCC}/last >>  ${TMPSCC}/filteredLast
 fi
 done
    paste  ${TMPSCC}/filteredThis  ${TMPSCC}/filteredLast |
       awk '{print $2,substr($3,1,2),($6+$7)*0.01*$18/(1-0.01*$18),$6,$7,($6+$7)/(1-0.01*$18),substr($3,1,5)}'|
       awk '{printf("%s | %s | %d | %d | %d | %d | %s |\n",$1,$2,$3,$4,$5,$6,$7)}'>>${TMPSCC}/ld_final1_${usr}
  
#  fi
  dt_sec=`expr $dt_sec + 86400`
done
cat ${TMPSCC}/ld_final1_${usr} > ${TMPSCC}/ld_final_${usr}
echo "___________|____|______|______|______|_______|_______|
Max
" >> ${TMPSCC}/ld_final_${usr}
grep -v "XX" ${TMPSCC}/ld_final1_${usr} | sort -n -k11 | tail -1 >> ${TMPSCC}/ld_final_${usr}
echo "___________|____|______|______|______|_______|_______|
	* This is eatimated values for east according to 
	* the %weight of east w.r.t. middle&west" >> ${TMPSCC}/ld_final_${usr}
cat ${TMPSCC}/ld_final_${usr}  |tee -a ${TMPSCC}/ld_final_${usr}.dat
;;
*) echo "Wrong Entry !! "; sleep 3 ; break
esac



echo

_PRT ${TMPSCC}/ld_final_${usr}.dat

while true
do
read sammary_req?"  Do you want to perfom sammary report ?
	A ) Alex
	E ) East
	M ) Middle
	W ) West
	N ) No , don't perform sammary report
  your choice >> "
  
case `echo "V${sammary_req}" | awk '{print toupper($1)}' | cut -c 1-2 ` in
VA)
SamOutFl="AlexLdFinal"
fild=6
sammary
;;
VE)
SamOutFl="EastLdFinal"
fild=3 
sammary
;;
VM)
SamOutFl="MiddleLdFinal"
fild=4
sammary
;;
VW)
SamOutFl="WestLdFinal"
fild=5
sammary
;;
V|VN)
break
;;
*)
echo "Wrong choice"
;;
esac
done

head -8 ${TMPSCC}/ld_final_${usr}.dat > ${TMPSCC}/ld_final_${usr}_avg.dat
grep "[0-9]" ${TMPSCC}/ld_final_${usr}.dat|grep "|" |
    sort -u > ${TMPSCC}/ld_tmp

cat ${TMPSCC}/ld_tmp >> ${TMPSCC}/ld_final_${usr}_avg.dat
grep "|" ${TMPSCC}/ld_final_${usr}.dat|
    grep [__] | sort -u >> ${TMPSCC}/ld_final_${usr}_avg.dat

grep -v -e " 0 " -e " - " ${TMPSCC}/ld_tmp |
   awk '{sum+=$11}END{print " Average :\t"sum/NR}'   >> ${TMPSCC}/ld_final_${usr}_avg.dat

cat ${TMPSCC}/ld_final_${usr}_avg.dat
_PRT ${TMPSCC}/ld_final_${usr}_avg.dat
