#!/bin/ksh
#--------------------------------------------------------------------------------
# TITLE   : aedc_PercntOutFeederLoading.ksh
# PURPOSE : Create Feeders & Subfeeders Daily Percntage Load Report  
#               call formated input file ${FlName} 
# GROUP   : SCC
# AUTHOR  : Abeer M. Elsayed  ( Alexandria Superviory Control Center )
# DATE    :  10/01/2006
#--------------------------------------------------------------------------
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions

IGNORE="@M-DP12.CTA8<HAVG@ -e @P:E-SS3.CTA31<HAVG@ -e @E-DP13.TOTAL_AMP<HAVG"

read ans?"Would U like update /aedc/cnf/scc/Feeder_CTs  y/[N] : "

case $ans in

y|Y) creat_Feeder_CTs.ksh ;;
*)echo "Keep Old /aedc/cnf/scc/Feeder_CTs ...." 
esac  
SCCTMP=/aedc/tmp/scc/FD_Ld
if [ ! -d ${SCCTMP} ]
then
mkdir ${SCCTMP}
fi

rm -f /aedc/tmp/scc/FD_Ld/*



IN_DIR=/home/sis/REPORTS/Wednesday_OUTSS_max_value
cp /dev/null $SCCTMP/PercntOut1
need=[A-Z]
es_lim=""
clear

cp /dev/null ${SCCTMP}/reject
echo " 

 	 Cable/Feeder 
  	Exceeded Limits Report
  ===================================
 "

var_mktime `date +%Y/%m/%d` "%Y/%m/%d"|read to_day
var_asctime `expr   $to_day - 86400` "%Y/%m/%d"|read best_day

read day?" Report Day [ $best_day ] >> "
if [ -z "$day" ]
then
day=$best_day
fi

read typ?" Out { SS ]Or Out [ DP ] (<CR> for all) : "
 if [[ -z "$typ" ]]
then
typ="DP -e [-]SS"
type=""
elif [[ "$typ" != "SS" && "$typ" != "DP"  ]]
then
echo "Wrong Entry "
exit
else
type=$typ
fi

echo $day | awk 'FS="/",OFS="_"{print $1,$2"/"$1,$2,$3".ld.Z"}' | read FlName1
echo $FlName1
FlName=${IN_DIR}/${FlName1}
read ex?"Exceeded limits Reports < [Y]/N > : "
echo "(${ex})"
if [[ -z "$ex" || "$ex" = "Y" || "$ex" = "y" ]]
then
ex="y"
exceed="( Exceeded Limits Report )"
echo "	Chose your threshold limit :
  1) operating limit 		.... [lim_fac=1]
  2) long term emergency(LTE)	.... [lim_fac=0.9]
  3) short term emergency(STE)	.... [lim_fac=0.9*0.7]
  4) chose estimated constant limit
  5) chose factor of operating limit
"
read cho?"Enter your choice (<CR> for operating limit) >> "
if [[ -z "$cho" ]]
then
cho=1
fi

case $cho in
1)
lim_fac=1
lim_tit="Operat  "
es_fac=1
;;
2)
lim_fac=0.9
lim_tit="Hi_Long "
es_fac=1
;;
3)
lim_fac=0.63		# 0.9*0.7=0.63 #
lim_tit="Hi_Short"
es_fac=1
;;
4)
lim_fac=1
read es_lim?"Enter estimated limit (<CR> for 1000) >> "
if [[ -z "$es_lim" ]]
then
es_lim=1000
es_fac=1
fi
lim_tit="$es_lim AMP"
;;
5)
lim_fac=1
read es_fact?"Enter estimated factor of operating limit (<CR> for 0.8) >> "
if [[ -z "$es_fac" ]]
then
es_fac=0.8
fi
lim_tit="${es_fac} of Operat  "
;;

esac
grep -v -e "^!" -e "^$" /aedc/cnf/scc/lim_set_cable_type | awk '{printf("s/@%s@/@%s@%d@/;",$2,$2,$3*0.63)}'|
     sed 's/;$//' | read sed_var	

echo "Ignoring ... ${IGNORE}..... "|sed 's/@/ /g;s/-e/&/g'
echo

  if [[ -z "$es_lim" ]]
  then
   zcat $FlName | grep -v -e "^$" -e "SPARE" -e "AUX[.]" -e "CAPACITOR" -e "I_SS" -e TR[1-7] | grep -e [-]${typ} |
       sed "s/^/$lim_fac@/" | sed "$sed_var" |
       awk  -v est_fact="${es_fac}" 'FS="@"{ if ($5*$1>($9*est_fact)) {print $0}}' > $SCCTMP/infile
  else
  zcat $FlName | grep -v -e "^$" -e "SPARE" -e "AUX[.]" -e "CAPACITOR" -e "I_SS" -e TR[1-7] | grep -e [-]${typ} |
  sed "s/^/${es_lim}@/" | awk 'FS="@"{ if ($5>$1) {print $0}}' > $SCCTMP/infile
  fi
else
ex="n"
exceed=""
lim_fac=1
zcat $FlName| grep -v -e "^$" -e "SPARE" -e "AUX[.]" -e "CAPACITOR" -e "I_SS"  -e TR[1-7] | grep -e [-]${typ} |
     sed "s/^/@/" | awk 'FS="@"{print $0}' > $SCCTMP/infile
fi

cat $SCCTMP/infile|grep -v -e  ${IGNORE} | while read line
do
echo "$line" | awk 'FS="@",OFS="\n"{print  $7,$5,$6,$8,$9}' |
 { read desc ; read val ; read CT ; read ca_type ; read lim ; }
 
#echo ${CT}
if [[ ! -z `grep -w "${CT}"  /aedc/cnf/scc/Feeder_CTs` ]]
	then
	grep -w "${CT}"  /aedc/cnf/scc/Feeder_CTs|
	sed "s/${CT}	/${CT}@/"|awk 'FS="@"{printf("%s\n",$2)}'|awk 'OFS="\n"{print $1,$2}' |
	awk 'OFS="\n"{print $1,$2}' |grep CT>>${SCCTMP}/reject
        grep -w "${CT}"  /aedc/cnf/scc/Feeder_CTs|sed "s/${CT}  /${CT}@/"|grep SS|awk 'FS="@"{print $1}'|
        awk '{print $2}'|grep CT>>${SCCTMP}/reject

fi
 
 echo "$line" |sed 's/P://'|awk '{print substr($0,index($0,":")-2,5)}' | read tm

echo ${CT} | cut -d"." -f1 | read ss
echo $CT | cut -d".CT" -f2 | sed 's/CTA//;s/CTK//'| read key
if  [ -z "$ca_type" ]
then
ca_type="_______________"
fi
desc=`echo $desc | sed 's/CT AMPS //;s/CT //;s/AMP //'`
  
  if [[ -z "$es_lim" ]]
  then
  echo "$val $lim $lim_fac" | awk '{printf("%d\n%d\n%d\n",$1*$3/$2*100,$1,$2/$3)}' |
        { read perc ; read val ; read lim ; }
  else
  echo "$val $es_lim" | awk '{printf("%d\n%d\n%d\n",$1/$2*100,$1,$2)}' | 
       { read perc ; read val ; read lim ; }
  fi

  if [ ${perc} -ge 100 ]
	then
#	echo "${ss}+${key}) ${desc}@${ca_type}@${lim}@${val}@(${perc}%)@${tm}@${CT}@" 
	
	echo "${ss}+${key}) ${desc}@${ca_type}@${lim}@${val}@(${perc}%)@${tm}@${CT}@" |
	awk 'FS="@"{printf("%-35s%-15s %5d %5d %8s%8s  %s\n",$1,$2,$3,$4,$5,$6 ,$7)}'|
	sed 's/+/@/'|
	grep ${need}|tee -a $SCCTMP/PercntOut1
    else
	echo "${ss}+${key}) ${desc}@${ca_type}@${lim}@${val}@${perc}%@${tm}" |
	awk 'FS="@"{printf("%-35s%-15s %5d %5d %8s%8s  %s\n",$1,$2,$3,$4,$5,$6 ,$7)}'|
	sed 's/+/@/'|
	grep ${need}|tee -a $SCCTMP/PercntOut1
  fi
done

var_asctime `var_mktime $day "%Y/%m/%d"` "%A %d/%m/%Y"|read day1
sort -u $SCCTMP/PercntOut1 >$SCCTMP/PercntOut3

cat ${SCCTMP}/reject|while read ln
do
#echo "${ln}"|awk 'OFS=" -e "{print $2"\$" ,$3"\$"}'|sed "s/-e \\$//"|read rej
grep -v "${ln}$" $SCCTMP/PercntOut3>$SCCTMP/PercntOut4
mv $SCCTMP/PercntOut4 $SCCTMP/PercntOut3
done

awk '{print substr($0,1,80)}'  $SCCTMP/PercntOut3 >$SCCTMP/PercntOut1

if [ -s ${SCCTMP}/PercntOut1 ]
then
echo "  
			
		 $type Outgoing feeders  Max. Load
		 		 $exceed
		 	$day1
	      _______________________________________________________


    Feeder Name		     Cable  	      Operat   Max   %ld      At
cell #			     Type	      Limit    AMP           hh:mm
=======================	     =============    ======  ===== =======  ====  " > $SCCTMP/PercntOut2
awk 'FS="@"{print $1}' $SCCTMP/PercntOut1 | sort -u | grep -v "^$" | while read ss
do
if [[ -z `echo ${ss} |grep SS`  ]]
then 
tit=" DP."
else
tit=" S/S"
fi
echo "\n$ss $tit\n-----------------" >> $SCCTMP/PercntOut2
grep "${ss}@" $SCCTMP/PercntOut1 | sed "s/${ss}@//" >> $SCCTMP/PercntOut2
done


dcc_ss_replace -i $SCCTMP/PercntOut2 |tee  $SCCTMP/PercntOut
else
echo "  

###################################################################
  			
    >>>>	No $exceed  <<<<
                   for Outging feeders 
                     $day1 
		 
#################################################################### "|tee $SCCTMP/PercntOut
fi
echo

_PRT $SCCTMP/PercntOut
