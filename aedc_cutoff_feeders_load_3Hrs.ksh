#!/bin/ksh
##------------------------------------------------------------------------------
# TITLE		:aedc_cutoff_feeders_load_3Hrs
# PURPOSE	:preapare report for load of cutoff feeders due to under frequency groups
#
# GROUP		:IS
# AUTHOR	:Alaa Nagy and  SCC S/W group 
# DATE		:17 Dec 2012
#UPDATE HISTORY	: 
#------------------------------------------------------------------------------
# @(#) $Header$
# $Log$
#------------------------------------------------------------------------------
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
SCCTMP=/aedc/tmp/scc/aedc

read action_ch?"
  
	a ) prepare 3Hrs report for a specific day
	b ) calculate prefault current sum.

     Your choice [a] >> "
if [ -z "$action_ch" ] 
then
action_ch=a
fi



Alx_amp_id=8533     # ALEX.TOTAL_AMP<HAVG
# 9775		  ALEX.TOTAL_AMP<INST
# 9871		  ALEX.TOTAL_AMP<15MIN
         
mktime `date +"%Y/%m/%d:19:00:00"`|read today
echo $today|awk '{print $1-24*60*60}' |read yestday
var_asctime ${yestday} %Y/%m/%d |read suggtime
clear
read  sorce?"  Choice i/p directory :
 		 1 ) CutOff_F
 		 2 ) Under_Freq
     Your choice [1] >> "
if [ -z "$sorce" ] 
then
sorce=1
fi


case $sorce in 
1)
Pre=CutOff 
in_dir=/aedc/cnf/scc/CutOff_F
read grp_lst?"Enter group numbers ( 1 2 3 5 4 6 ... etc 20 I1 I2 I3 I4 ) <CR for all> >> "
if [ -z "$grp_lst" ]
then
grp_lst="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 I1 I2 I3 I4"
fi
base_fl_nm="grp_"
accStrt=""

;;
2)
Pre=UF
in_dir=/aedc/cnf/scc/Under_Freq
read grp_lst?"Enter group numbers ( 1 2 3 5 4 6 7 ) <CR for all> >> "
if [ -z "$grp_lst" ]
then
grp_lst="1 2 3 4 5 6 7"
fi
base_fl_nm="UF_"
accStrt="P:"

;;

*) echo "Bad Entry .. Try Again ..."
exit

esac


case "$action_ch" in 
b|B)
read from?"Enter date on the form yyyy/mm/dd:HH:MM:SS >> "
if [ -z "${from}" ]
then
from=${suggtime}:00:00:00
fi

read to?"Enter date on the form yyyy/mm/dd:HH:MM:SS >> "
if [ -z "${to}" ]
then
to=${suggtime}:23:59:59
fi
echo "filtering on $from to $to"
date1_asc="$from"
date6_asc="$to"
filter_his_date_range "SCL"

grep "TC" $SCCTMP/rtu_test_SCL > $SCCTMP/SCL_TC
for grp in $grp_lst
do
fl=${in_dir}/${base_fl_nm}${grp}
echo working with $fl
        grep -v "^#" $fl|
        awk 'FS="@"{print $2}' | sed 's/TC //'|
        while read ln
        do
        grep  "$ln" $SCCTMP/SCL_TC|grep "SCL SUCC MANUAL ENTRY" |
	 awk 'FS="SCL SUCC MANUAL ENTRY"{print $2}'
        done|
        awk '{sum+=$1}END{print "Total Amp is "sum ,",MW is " sum/58 }'

done
;;

*)

read date?"Enter date on the form ${suggtime} >> "

if [ -z "${date}" ]
then
date=${suggtime}
fi

hr_lst0="04 15 19"
read hr_lst?" Enter 3 peak hours (<CR> for default [04 15 19]) >> "
if [ -z "$hr_lst" ]                                                                            
then
hr_lst="$hr_lst0"
fi
echo $hr_lst|awk '{printf ("%s\n%s\n%s\n",$1,$2,$3)}'|{ read hr1 ; read hr2 ; read hr3 ; }

echo "${Pre}_${date} ${hr_lst}"|sed 's-/-_-g;s- -:-g'|read OUTPUT
echo $SCCTMP/${OUTPUT}


echo "	${Pre} Groups Load\n	==================" > $SCCTMP/${OUTPUT}

mktime `echo ${date}|cut -c 1-11`:${hr1}:00:00 | read date_sec1
mktime `echo ${date}|cut -c 1-11`:${hr2}:00:00 | read date_sec2
mktime `echo ${date}|cut -c 1-11`:${hr3}:00:00 | read date_sec3

data_src_select
#echo "Selecting data from historical files" 
#data_src=2
#---------------------------------------------------

if [ "${data_src}" = "2" ]
then
var_asctime $date_sec1 "/aedc/data/nfs/historical/%d_%m_%Y.acc.Z" | read in_data_fl
zcat $in_data_fl | grep -e ${date_sec1} -e ${date_sec2} -e ${date_sec3} > ${SCCTMP}/in_data
fi
##############################################################

case ${data_src} in
1)
echo "select str(C0432_date)+'@'+str(C0432_value_r,10,0)
from T0432_data	where C0432_date in (${date_sec1},${date_sec2},${date_sec3})
and C0401_aid =${Alx_amp_id}
go"|isql -U dbu -P dbudbu | grep "@" |sed 's/@/ /' > ${SCCTMP}/in_data_alex		    
;;
2)
awk  -v id="${Alx_amp_id}" '$1==id{printf("%s %-8d\n",$2,$3)}' $SCCTMP/in_data > $SCCTMP/in_data_alex
;;
esac
grep "$date_sec1" $SCCTMP/in_data_alex | awk '{print $2}' | read alex_val1
grep "$date_sec2" $SCCTMP/in_data_alex | awk '{print $2}' | read alex_val2
grep "$date_sec3" $SCCTMP/in_data_alex | awk '{print $2}' | read alex_val3

########################################################

echo $date|awk 'FS="/"{print substr($3,1,2)"/"$2"/"$1}'|read date1
GrandTotal="0 0 0"
grp_cnt=0

for grp in ${grp_lst}
do

echo ${grp_cnt}|awk '{print $1+1}'|read grp_cnt
in_fl=${in_dir}/${base_fl_nm}${grp}
out_fl=${SCCTMP}/Amp_grp_${grp}
rm -f ${out_fl} ${out_fl}?
echo |awk '{printf "\f" }' |tee  $out_fl
echo "
	     Group [ ${grp} ] Load 
	On ${date1} at Hours [ $hr_lst ]
	Alex. Load   				 ${alex_val1}, ${alex_val2} , ${alex_val3} Amp
	====================================
						     Amp.  Amp.   Amp.
SubStation			    Feeder	      $hr1    $hr2     $hr3
--------------------        -------------------      ----  ----   ---- " |tee  -a $out_fl
sum=0
cp /dev/null  ${out_fl}A_1
grep -v -e "^$" -e "^#" ${in_fl}|while read ln
do
echo $ln | awk 'FS="@",OFS="\n"{print $1,$2}'|sed 's/<HAVG//'| sed  's/PF-CT/CT/'|
			{ read acc ;sed 's/^TC //'|read desc ; }

acc1=${acc}
echo ${acc1} |  sed 's/P:MAX/P:W-MAX/;s/M-VALUE.CA-1190-K22/M-KRZ220/;s/M-VALUE.CA-SKZ-903/M-KRZ220/;
s/M-VALUE.CA-2019-K3/ABIS220KV/;s/M-VALUE.CA-3421-K12/ABIS220KV/;s/P://;s/E-SS1/E-SS1T/;s/E-DP13/E-SS1T/;s/W-DP27/W-OBORG/;s/W-DP22/W-OBORG/;s/W-DP17/W-MOGAMA/'|
awk 'FS="." {print $1}'| read SS

case ${SS} in
#	E-SIOF)
#	echo ${acc}|sed 's/P://;s/CT/CB/'|read CB_NM
#echo "select  C0007_point_desc from T0007_point
#where rtrim(C0003_group_name)+'.'+rtrim(C0007_point_name) like '${CB_NM}'
#go"|isql -U dbu -P dbudbu | head -3 | tail -1|sed 's/ CB SW //;s/CT VALUE FOR //'|read desc
#val="NT"
#;;
#	W-MAX)
#echo ${acc}|awk 'FS="."{print $2}'|sed 's/_AMP//'|read desc
#val="NT"
#;;
#	M-VALUE)
#val="NT"
#;;
	M-KRZ220|M-SEMOH)
echo ${acc}|awk 'FS="."{print $2}'|awk 'FS="-"{print $2}'|read desc
val="--"
;;

M-DP*|W-DP*|E-DP*)
if [[ ! -z "`echo $acc1|grep M-VALUE`" || ! -z "`echo $acc1|grep M-DP[1-9]`" ]] && [[ ! -z "`echo $desc|grep KARMOZ`" ]]
then
echo ${acc1}|awk 'FS="."{print "M-KRZ220."$2}'|read acc
SS="M-KRZ220"
fi

if [[ ! -z "`echo $acc1|grep M-VALUE`" || ! -z "`echo $acc1|grep M-DP[1-9]`" ]] && [[ ! -z "`echo $desc|grep SEMOH`" ]]
then
echo ${acc1}|awk 'FS="."{print "M-SEMOH."$2}'|read acc
SS="M-DP22"
#echo ${acc}|sed 's/M-VALUE/M-SEMOH/'|read acc
fi

if [[ ! -z "`echo $acc1|grep W-DP[1-9]`" ]] && [[ ! -z "`echo $desc|grep AMRIA`" ]]
then

echo ${acc1}|awk 'FS="."{print "W-AMRIA."$2}'|read acc
SS="W-AMRIA"
fi
if [[ ! -z "`echo $acc1|grep W-DP[1-9]`" ]] && [[ ! -z "`echo $desc|grep MAX`" ]]
then
echo ${acc1}|awk 'FS="."{print "W-MAX."$2}'|read acc
SS="W-MAX"
fi

echo ${acc1}|awk 'FS="."{print $1}'| read DP
echo "$desc"|awk -v DP=$DP '{print "( "DP" )"$0}'|
sed 's/KARMOZ 220//;s/KARMOZ 220 KV//;s/SEMOHA 220//;s/SEMOHA / /;s/ SS/ /;s/ KV //'|read desc
#echo $SS
#############################################################################################################################################
;; 


esac

case $data_src in
1)
#echo ${accStrt}${acc1}
echo "select str(C0432_date)+'@'+str(C0432_value_r,4,0)
from T0432_data	
where C0432_date in (${date_sec1},${date_sec2},${date_sec3})
and C0401_aid in (select C0401_aid from T0401_accounts
		  where C0401_name like '%${acc1}<HAVG' and C0401_state='A'  )
go"|isql -U dbu -P dbudbu | grep "@" |sed 's/@/ /' > $SCCTMP/in_data_acc		    
;;

2)
echo "select C0401_description+'@'+str(C0401_aid) from T0401_accounts
where C0401_name like '%${acc1}<HAVG' and C0401_state='A'
go"|isql -U dbu -P dbudbu | head -3 | tail -1 | 
awk 'FS="@"{print $1"\n"$2}' | { read # desc ; 
				 read id ; }
awk  -v id="$id" '$1==id{printf("%s %-5d\n",$2,$3)}' $SCCTMP/in_data > $SCCTMP/in_data_acc
;;
esac
if [ "$val" != "NT" ]
then
 
grep "$date_sec1" $SCCTMP/in_data_acc | awk '{print $2}' | read val1
grep "$date_sec2" $SCCTMP/in_data_acc | awk '{print $2}' | read val2
grep "$date_sec3" $SCCTMP/in_data_acc | awk '{print $2}' | read val3


if [ -z "${val1}" ]
then
val1="BC"
fi
if [ -z "${val2}" ]
then
val2="BC"
fi
if [ -z "${val3}" ]
then
val3="BC"
fi
else
val1="NT"
val2="NT"
val3="NT"
fi
echo "${SS}@ $desc @ $val1 @ $val2 @ $val3" | sed 's/CTS //;s/AVG_CURRENT FOR //'|
sed 's/N@/@/;s/-T5@/@/;s/E@/@/'|tee -a ${out_fl}A_1
done
sort ${out_fl}A_1  >${out_fl}A		# while read acc

cat ${out_fl}A|grep -e SS -e M-DP12 -e M-DP22  -e E-SIOF  -e M-KRZ220 -e W-MAX -e  W-AMRIA  |
awk -v cnt=0   'FS="@"{sum1+=$3;sum2+=$4;sum3+=$5}{if($1==PRV){SS="                         ";cnt1="  ";pr=" "}
else{SS=$1;PRV=$1;cnt+=1;cnt1=cnt;pr=")"}
{printf("%-2s%s %s%-24s%5s%5s%5s\n",cnt1,pr,SS,$2,$3,$4,$5) }
}END{print cnt"@"sum1"@"sum2"@"sum3}'> ${out_fl}B
grep "@" ${out_fl}B|awk 'FS="@"{print $1"\n"$2"\n"$3"\n"$4}'|{ read cnt ; read sum1 ;  read sum2 ; read sum3 ; }

grep -v "@" ${out_fl}B|tee  -a ${out_fl}

if [ "$sorce" = "1" ]
then
cat ${out_fl}A|grep -v -e SS -e M-DP12 -e M-DP22  -e E-SIOF  -e M-KRZ220 -e W-MAX -e  W-AMRIA  |
awk -v grp=${grp} -v cnt=$cnt -v sum1=$sum1 -v sum2=$sum2 -v sum3=$sum3 'BEGIN{print "Distribution Points\n=================" };
FS="@" {sum1+=$3;sum2+=$4;sum3+=$5}
{if($1==PRV){SS="                         ";cnt1="  ";pr=" "}
else{SS=$1;PRV=$1;cnt+=1;cnt1=cnt;pr=")"}
{printf("%-2s%s %s%-24s%5s %5s %5s\n",cnt1,pr,SS,$2,$3,$4,$5) }}'|grep -v "@"  |tee -a  $out_fl
fi

echo "${grp} $sum1 $sum2 $sum3"|
awk  -v spc=""  -v ALX1=${alex_val1} -v ALX2=${alex_val2} -v ALX3=${alex_val3}  '
{printf("------------------------------------------------------------------\n  Total Group[%d]%-25s~%-12s%-5d %-5d %-5d Amp\n%-55s%.1f%%   %.1f%%    %.1f%%\n" , 
$1,spc,spc,$2,$3,$4,spc,$2/ALX1*100 ,  $3/ALX2*100, $4/ALX3*100)}' |tee -a  $out_fl
cat ${out_fl} >> ${SCCTMP}/${OUTPUT}
tail -2 ${SCCTMP}/${OUTPUT}|grep Total|awk '{printf("%6d %6d %6d", $4/58, $5/58, $6/58)}'|read sumMw
if [ $grp_cnt -eq 1 ]
then
GrandTotal=${sumMw}
else
echo ${GrandTotal} ${sumMw}|awk  '{print $1+$4,$2+$5,$3+$6}'|read GrandTotal 
echo  |awk -v grp=${grp_cnt} '{if((grp/2)==int(grp/2)){printf("\f")}}'
fi
done		# for grp in $grp_lst

if [ ${grp_cnt} -gt 1 ]
then
echo "------------------------------------------------------------------
 Grand Total[ ${grp_lst} ]                  
 				  ~	               ${GrandTotal}
				  
NOTE : values not available from SCADA system :
       NT	nontelemetred
       BC	temprory bad communication				  " MW|tee -a $SCCTMP/${OUTPUT}
fi

dcc_ss_replace -a  ${SCCTMP}/${OUTPUT} >${SCCTMP}/${OUTPUT}1

echo
_PRT ${SCCTMP}/${OUTPUT}1

;;
esac 	# case "$action_ch" in
