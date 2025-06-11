#!/bin/ksh
. aedc_SCC_functions

id | cut -d")" -f1 | cut -d"(" -f2 | read usr
mktime `date +"%Y/%m/%d:23:59:59"`|awk '{ print $1-86400}'	 |read yesterday
mktime `date +"%Y/%m/%d:00:00:00"`|awk '{ print $1-(24*60*60)*7}'|read week_age
        var_asctime $yesterday "%d/%m/%Y"|read sugg_day
        var_asctime $week_age "%d/%m/%Y"|read sugg_day_2
read d1_t?"Please Enter From  Date   < $sugg_day_2 > : "
read d2_t?"Please Enter To    Date   < $sugg_day >   : "

if [[ -z  ${d1_t} ]]
  then
    d1_t=$sugg_day_2
fi
if [[ -z ${d2_t} ]]
  then
    d2_t=$sugg_day
  fi
echo $d1_t |awk 'FS="/"{printf("%s/%s/%s:00:00:01" ,$3,$2,$1)}'|read d1  
mktime $d1 |read asc_from
echo $d2_t |awk 'FS="/"{printf("%s/%s/%s:23:59:59" ,$3,$2,$1)}'|read d2  
mktime $d2 |read asc_to
day_sec=$asc_from

read Cutoff?"Would U consider CuttOff load < [ Y ] / N > : "
 if [ -z "${Cutoff}" ]
 then
Cutoff="Y"
fi
case ${Cutoff} in
n|N) ALEX=ALEX.TOTAL_MWA 
     ALEX_NM="ALEX.TOTAL_MWA<HMAX" 
     NOT_INC=ALEX.TOTAL_MWA_CutOff 
     STAT=" " 
     sign="+" 
     ex1=""
     ex2=""
     ex3=""
     ex4=""
     ex6=""
     ;;
     
y|Y) ALEX=ALEX.TOTAL_MWA_CutOff  
     ALEX_NM="ALEX.TOTAL_MWA<HMAX" 
     NOT_INC=balabalbalaaa 
     STAT="With Cutoff" 
     sign="XX"
     ex1="______"
     ex2="      |"
     ex3="Cutoff|"
     ex4="_MW___|"
     ex6="______|"
     ;;
     
*) echo "Wrong Entry "
   exit
esac

echo "
select C0401_aid from T0401_accounts
where C0401_name='ALEX.TOTAL_MWA<HMAX'
go"|isql -Udbu -Pdbudbu | grep  "[0-9]" |grep -v -e row -e C0401_aid|read id

clear

var_asctime  $asc_from  "%A %d/%m/%Y" |read from
var_asctime  $asc_to  "%A %d/%m/%Y" |read to
echo " 
     Alexadria Distribution load
      Max. & Min   Mwatts  
      $from - $to  
				  $STAT
______________________________________$ex1
                    |     Maximum    |$ex2
         Day        |  Time |  MW    |$ex3
____________________|_______|________|$ex4" |tee  /tmp/scc/max_load_${usr}

path=/home/sis/REPORTS/DAILY_MAX_VALUE
while [ ${day_sec} -le  ${asc_to} ]
do
var_asctime ${day_sec} "${path}/%Y_%m/%Y_%m_%d.ld.Z"| read f
zcat ${f}|grep -e "${ALEX_NM}" -e "${ALEX}"|grep -v -e MINIMUM -e ${NOT_INC} |tail -1|awk '
FS="@"{printf("%.1f\n%d\n%s\n", $4, $5,$2)}'| { read Maxmw ; read Maxdt ; read NM ; }
zcat ${f}|grep -e "${ALEX_NM}" -e "${ALEX}"|grep -v -e MINIMUM|tail -1|awk '
FS="@"{printf("%s\n",$2)}'| { read NM ; }
echo ${NM}|sed "s/ALEX.TOTAL_MWA_CutOff //;s/${ALEX_NM}//g"|read Cuttoff_val
zcat ${f}|grep  -e "${ALEX_NM}" -e "${ALEX}"|
grep MINIMUM|tail -1|awk 'FS="@"{print  $4 ,$5}'|read Minval

echo ${Minval}|awk '{printf("%.1f\n%d\n", $1, $2)}'| 
{ read Minmw ; read Mindt ; }

var_asctime  ${Maxdt}  "%A %d %m %Y %H %M" |
     awk '{printf(" %-10s%s/%s/%s@%s:%s" , $1,$2,$3,$4,$5,$6)}'|
     read max_asc_occ_dd

var_asctime  ${Mindt} "%H:%M" |read min_asc_occ_tt

case ${Cutoff} in
n|N)
echo "${max_asc_occ_dd}@${Maxmw}@${Minmw}@${min_asc_occ_tt}@${Cuttoff_val}"|
  awk  -v S=${sign} 'FS="@" {{if($6>0){S1=S}else{S1=" "}}printf("%-15s| %-5s | %6s |\n" , $1,$2,$3)}'|
  sed 's/XX/ /'|tee  -a  -a  /tmp/scc/max_load_${usr}
;;

y|Y)
echo "${max_asc_occ_dd}@${Maxmw}@${Minmw}@${min_asc_occ_tt}@${Cuttoff_val}"|
  awk  -v S=${sign} 'FS="@" {{if($6>0){S1=S}else{S1=" "}}printf("%-15s| %-5s | %6s |%s%4s |\n" , $1,$2,$3,S1,$6)}'|
  sed 's/XX/ /'|tee  -a  /tmp/scc/max_load_${usr}
;;
esac

day_sec=`expr ${day_sec} + 24 \* 60 \* 60`
done 
grep ":" /tmp/scc/max_load_${usr}|sort  -r -n -k5 | head -1 |
awk '{print substr($0,1,50)}'|read maxim

echo "____________________|_______|________|$ex6
${maxim}
____________________|_______|________|$ex6" |tee -a /tmp/scc/max_load_${usr}

echo
_PRT /tmp/scc/max_load_${usr}


