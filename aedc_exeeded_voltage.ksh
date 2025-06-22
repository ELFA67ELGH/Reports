#!/bin/ksh

. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
IN_FILE=/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat
OUT_FILE=${SCCTMP}/SS_VoltExd
tail_FLG="false"
SCCCNF=/aedc/cnf/scc
echo " Substation TR Voltage exceeded limit kV" | tee ${OUT_FILE}
print -n "" > ${OUT_FILE}_sub

read dev?"Enter voltage limit % dev. (<CR> default : 5 ) >> "
   if [ -z "${dev}" ]
   then
   dev=5
   fi

enter_range
grep -w -e NAME -e DESCRIPTION $IN_FILE | awk '{if ($1=="NAME"){printf("%s\t",$3)}
   else
   print $5}'| awk 'FS="."{if (NF==3)print $0}'|sed 's/\./ /2'|
   awk 'OFS="\t"{print $1,$3}'| sort  > $SCCTMP/acc_list1
   
read filter?"  Are you interrest in certain SS ?
	E  for East	  E-SS for TEL-East only
	M  for Middle	  M-SS for TEL-Middle only
	W  for West	  W-SS for TEL-West only
		<CR> for all
		  >> "
  if [ -z "${filter}" ]
  then
  cp  $SCCTMP/acc_list1 $SCCTMP/acc_list
  else
  grep "^$filter" $SCCTMP/acc_list1 > $SCCTMP/acc_list
  fi
  echo " $date1_asc -> $date6_asc

 For $filter SS 	Exceeded ${dev}% kVolt
==========================================================================
TR	       exeeded	 	  returned		    Peak
	    Time	  kV	duration  kV		Time	      kV
	yyyy/mm/dd:hh:mm	 d/hh:mm	    yyyy/mm/dd:hh:mm
--------------------------------------------------------------------------" >> $OUT_FILE
data_src_select  

#grep PTA /aedc/cnf/scc/PTnot11KV | awk '{printf("@%s.%s@ ,", $1,$2)}'|sed "s/@/'/g"|read Not11kV_pnt
#echo "select C0401_name from T0401_accounts where C0401_source_id_int in 
#(select C0007_point_id from T0007_point 
#where rtrim(C0003_group_name)+'.'+rtrim(C0007_point_name) in ($Not11kV_pnt 'KK'))
#and C0401_name like '%15MIN'
#go"|isql -U dbu -P dbudbu | grep 15MIN  > ${SCCTMP}/PTnot11KV_acc

while read ln	# from $SCCTMP/acc_list 
do
echo $ln | awk '{print $1}' | read acc

if [[ -z `grep -w "$acc" ${SCCCNF}/PTnot11KV_acc` ]]
then

echo ${dev}| awk '{printf("%.1f",(1+($1/100))*10.5)}'|read lim
else

grep -w "$acc" ${SCCCNF}/PTnot11KV_acc|awk '{print $2}'|read volt_rate
#print -n "${acc}  ${volt_rate} kV volt_rate  "
echo ${dev} ${volt_rate}|awk '{printf("%.1f", (1+($1/100))*$2)}'|read lim
fi
echo "working ${acc}. . .Limit ${lim}"
echo "\n${acc}" >> ${OUT_FILE}_sub
   if [ $data_src = 2 ]			# o/p variable of function: data_src_select
   then
   filter_acc_date_range -n "${acc}"  > /dev/null
   else
   filter_acc_date_range -n "${acc}" -DB  > /dev/null
   fi
sed "s/^/${lim} /" $SCCTMP/Filter_acc1 | awk '{if ($4 > $1) {print $3,$4} else printf"\n"}' | 
         grep -p [0-9] > $SCCTMP/acc_exeed
head -1 $SCCTMP/acc_exeed | awk '{printf("%d\t%.2f\n" ,$1,$2)}' > $SCCTMP/alrm_sec


print -n "" > $SCCTMP/norm_sec
print -n "" > $SCCTMP/pk_sec
print -n "" > $SCCTMP/alrm_tm
print -n "" > $SCCTMP/norm_tm
print -n "" > $SCCTMP/pk_tm
print -n "" > $SCCTMP/exeed_tm

last_brk_ln=0
cat -n $SCCTMP/acc_exeed | awk '{if (NF==1){print $0}}' | 
	while read brk_ln
	do
	head -`expr $brk_ln - 1` $SCCTMP/acc_exeed | tail -1 | awk '{printf("%d\t%.2f\n" ,$1,$2)}'>> $SCCTMP/norm_sec
	head -`expr $brk_ln + 1` $SCCTMP/acc_exeed | tail -1 | awk '{printf("%d\t%.2f\n" ,$1,$2)}' >> $SCCTMP/alrm_sec
	head -`expr $brk_ln - 1` $SCCTMP/acc_exeed | tail -`expr $brk_ln - $last_brk_ln` |
	   grep [1-9] | sort -n -k2 | tail -1 | awk '{printf("%d\t%.2f\n" ,$1,$2)}' >> $SCCTMP/pk_sec 
	last_brk_ln=$brk_ln
	done		# while read brk_ln

grep [1-9] $SCCTMP/alrm_sec |
	while read sec1
	do
 	echo $sec1|awk '{print $1 }'| read sec
 	echo $sec1|awk '{print $2 }'| read val
 	var_asctime ${sec} "%Y/%m/%d:%H:%M" | read alrm_tm  
	echo "${alrm_tm}   $val" >> $SCCTMP/alrm_tm
	done 

grep [1-9] $SCCTMP/norm_sec |
	while read sec1 	
	do
 	echo $sec1|awk '{print $1+900}'| read sec		# 900 sec = 15 min X 60 sec/min
	grep $sec $SCCTMP/Filter_acc1 | awk '{printf("%.2f\n",$3)}' | read val
	if [ -z "$val" ]
	then
	val="T.end"
	tail_FLG="true"
	fi
	var_asctime $sec "%Y/%m/%d:%H:%M" |read norm_tm
        echo "${norm_tm}   ${val}" >> $SCCTMP/norm_tm
	done
	 
grep [1-9] $SCCTMP/pk_sec |
	while read sec1
	do
 	echo $sec1|awk '{print $1 }'| read sec
 	echo $sec1|awk '{print $2 }'| read val
 	var_asctime ${sec} "%Y/%m/%d:%H:%M" | read pk_tm  
	echo "${pk_tm}   $val" >> $SCCTMP/pk_tm
	done 

paste -d"\t" $SCCTMP/alrm_sec $SCCTMP/norm_sec | grep [1-9] |
	awk '{print $3+900-$1}'|while read sec			# 900 sec = 15 min X 60 sec/min
	do
	var_asctime `expr $sec - 7200` "%H:%M" | sed "s/^/$sec /" | 
	   awk '{printf("%d/%s\n",$1/86400,$2)}' >> $SCCTMP/exeed_tm
	done

#paste -d"\t" $SCCTMP/alrm_tm $SCCTMP/norm_tm | sed 's/2/	2/' >> ${OUT_FILE}_sub
paste $SCCTMP/alrm_tm $SCCTMP/norm_tm $SCCTMP/exeed_tm $SCCTMP/pk_tm |
    awk '{print $1,$2,"\t",$5,$4,"\t   ",$6,$7}' |
    sed 's/2/	2/' >> ${OUT_FILE}_sub

#else
#echo " ${acc}	is not 11 Kvolt rate"|sed 's/<15MIN//'
#fi
done < $SCCTMP/acc_list 

grep -p ":" ${OUT_FILE}_sub > ${OUT_FILE}_sub1		# to filter acc's not exeed limit 
grep "<" ${OUT_FILE}_sub1 | awk 'FS="."{print $1}' | sed 's/N$//;s/E$//' | sort -u |
	while read ss
	do
	echo "\n$ss\n================" >> $OUT_FILE
	grep -w -e "$ss" -e "${ss}N" -e "${ss}E" $SCCTMP/acc_list | sort -k2 |
		while read ln
		do
		echo $ln | awk 'OFS="\n"{print $1,$2}' | { read acc ; read tr ; }
		if [ ! -z "`grep -p $acc ${OUT_FILE}_sub1`" ]
		then
		  grep -p "$acc" ${OUT_FILE}_sub1 | grep : | sed "1s/^/$tr/" >> $OUT_FILE
		  echo "\t__________________________________________________________________" >> $OUT_FILE
		fi  
		done		# while read ln
	done			# while read ss

if [ "$tail_FLG" = "true" ]
then
echo "\nNote:
T.end >> voltage returned after the end of time range determined;
	 so that the return value is not available " >> $OUT_FILE
fi
dcc_ss_replace -a $OUT_FILE 
asc_print $OUT_FILE  -nH -1 -nd -B -F10 -p -nL
