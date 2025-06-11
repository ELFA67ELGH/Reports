#!/bin/ksh

. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
SCCTMP=/tmp/scc/LD_SHAD
if [ ! -d  ${SCCTMP} ]
then
mkdir ${SCCTMP}
else
rm -f ${SCCTMP}/*
fi


while true
do
enter_his_date_range
mktime $date1_asc | read strt
mktime $date6_asc | read end
var_asctime  $end  " %A %d/%m/%Y  %H:00"|read Hr
var_asctime  $end  "%d_%m_%Y"|read dy

#read Tot_mw1?"Please Enter  Total Value Needed : "
#read Tm?" Night [ N ] or Morning [ M ]: " 

#case  $Tm in
#M|m ) ft=.95 ;;
#*)ft=.98   ;;
#esac

ft=.98

echo ${Tot_mw1} $ft |awk '{print $1*$2}' |read Tot_mw

echo "
select C0439_alm_text from T0439_almhc where
C0439_alm_text like '%SCL SUCC MANUAL ENTRY%'
and C0438_date between $strt and $end
go" | isql -Udbu -Pdbudbu |awk 'FS="SCL SUCC MANUAL ENTRY"{print $1,$2}'|
awk 'FS="      D   "{print $1,$2}'|
awk 'FS=" TC "{print $1,$2}'|
awk 'FS="ascsys[1-2]:"{print $1,$2}'|awk 'FS="_CB"{print $1}'|
awk '{print substr($0,2,68)}'|grep -e "[E,M,W]-"| 
grep -e "-SS" -e "-DP" > ${SCCTMP}/bb

grep -e "E-" ${SCCTMP}/bb|awk '{print substr($0,60,17)}'|
awk '{sum+=$1}END{printf("%7d\n%7.1f\n", sum,sum/55)}'|{ read n ; read f ; } 

grep -e "M-" ${SCCTMP}/bb|awk '{print substr($0,60,17)}'|
awk '{sum+=$1}END{printf("%7d\n%7.1f\n", sum,sum/55)}'|{ read m ; read u ; } 

grep -e "W-" ${SCCTMP}/bb|awk '{print substr($0,60,17)}'|
awk '{sum+=$1}END{printf("%7d\n%7.1f\n", sum,sum/55)}'|{ read g ; read h ; } 

echo "$g $m $n"|awk '{sum=$1 + $2  +$3 }{printf("%7d\n%7.1f\n", sum,sum/55)}'|{ read k ; read p ; }


echo ${Tot_mw} $p |awk '{print $1-$2}' |read miss
echo " Total cuttoff Value Needed = ${Tot_mw} => OutOf   $p    >> Missing  =[[ ${miss} MW ]] "   

echo " 

Load Shedding	Needed MW = [ ${Tot_mw1} ]	
==================================
Date 		$Hr		

Total Middle    = ${m} Amp
Total Middle Mw = ${u}
Total West      = ${g} Amp
Total West   Mw = ${h}
-----------------------------------------------
Total       = ${k} Amp   Total   Mw = $p
" |tee   ${SCCTMP}/Total_rep

real_nm=cutoff_real_${dy}

read realfile?" Write File name ( For Example. ${real_nm} ) >> "

if [[ -z "${realfile}" ]]
then
realfile="${real_nm}"
fi

read add?" Add Reslut to  /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile}  y / [n]  : "
case $add in
y|Y )
cat ${SCCTMP}/Total_rep|tee -a    /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile}

chmod 777 /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile}

#rcp ascdts:/home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile} ascoper1:/aedc/tmp/scc/
#rcp ascdts:/home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile} ascoper2:/aedc/tmp/scc/

#echo " You can find this file under ( /aedc/tmp/scc/ ) "

_PRT /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile}
;;
*) echo "Data not added";;
esac




##        E      M    W        A
## Amp  ${n}   ${m}  ${g}    ${k}
## MW   ${f}   ${u}  ${h}    ${p} 

read DCC?"Please Enter  DCC to be Real   [ M , E  or W ]  :  "

case "${DCC}" in
m|M) FX=${u}  ;  Var1=${f}  ; Var2=${h} 
	mc=$m ; uc=$u

echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr1)}'|read fc
echo $fc |awk  '{printf("%d\n", $1*55)}'|read nc
echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr2)}'|read hc
echo $hc |awk  '{printf("%d\n", $1*55)}'|read gc
;;
E|e) FX=${f}  ;  Var1=${u}  ; Var2=${h}
nc=$n ; fc=$f
echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr1) }'|read uc
echo $uc |awk  '{printf("%d\n", $1*55)}'|read mc
echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr2)}'|read hc
echo $hc |awk  '{printf("%d\n", $1*55)}'|read gc
;;
W|w) FX=${h}  ;  Var1=${u}  ; Var2=${f}
gc=$g ;  hc=$h 
echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr1) }'|read uc
echo $uc |awk  '{printf("%d\n", $1*55)}'|read mc
echo ${Tot_mw} ${FX}|awk  -v vr1=$Var1 -v vr2=$Var2 '{printf("%4.2f\n", ($1-$2)/(vr2+vr1)*vr2)}'|read nc
echo $nc |awk  '{printf("%d\n", $1*55)}'|read gc
;;


*)
    Var1=${f} ; Var2=${u} ; Var3=${h}

  echo ${Tot_mw} |awk -v vr1=$Var1 -v vr2=$Var2  -v vr3=$Var3  '
  {printf("%5.2f\n", $1/(vr1+vr2+vr3))}'|read fact
  
# for winter
fact=`echo $fact|awk '{print $1*0.9}'`



  echo "Factor ~ $fact  .... "
  
  if [[  ${fact} > 1.1  ]]
  then
  echo $f $fact |awk  '{printf("%6.2f\n" ,$1*$2)}'|read fc
  echo $u $fact |awk  '{printf("%6.2f\n" ,$1*$2)}'|read uc
  echo $h $fact |awk  '{printf("%6.2f\n" ,$1*$2)}'|read hc
  echo $fc |awk  '{printf("%d\n", $1*55)}'|read nc
  echo $uc |awk  '{printf("%d\n", $1*55)}'|read mc
  echo $hc |awk  '{printf("%d\n", $1*55)}'|read gc
  
else
echo  "  >>>Not Need Modification...:D "

fc=$f  ; uc=$u ; hc=$h
nc=$n  ; mc=$m ; gc=$g
fi


esac

echo ${fc} ${uc}  ${hc} |awk '{print $1+$2+$3}'|read pc
echo ${pc} |awk  '{printf("%d\n", $1*55)}'|read kc



echo " 

Load Shedding	Needed = [ ${Tot_mw1}    MW ]
===================================================
Date 		${Hr}			



Total Middle    = ${mc} Amp
Total Middle Mw = ${uc}
Total West      = ${gc} Amp
Total West   Mw = ${hc}
-------------------------------------
Total       = ${kc} Amp       Total    Mw = ${pc}
                                                   ======
"|tee ${SCCTMP}/Total_rep_fac 


calc_nm=cutoff_calc_${dy}
read calcfile?" Write File name ( For Example. $calc_nm ) >> "

if [ -z ${calcfile} ]
then
realfile=${calc_nm}
fi

read add?" Add Reslut to  /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${calcfile}  y / [n]  : "
case $add in
y|Y )
cat ${SCCTMP}/Total_rep_fac |tee -a  /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${calcfile}  

chmod 777 /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${calcfile}

_PRT /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/$calcfile
;;
*) echo " >>>> Data not added to  /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/$calcfile" ;;
esac




read ans?" Do U need Details [ y/n ]  : "
case $ans  in
Y|y)
echo "	Date $date6_asc
        data        EAST ( SS & DP )               CB Descr.                    Amp.

 ==================================================================================== " |tee  ${SCCTMP}/eload
grep  "E-"  ${SCCTMP}/bb|sort -k2 -u >${SCCTMP}/est
dcc_ss_replace -a ${SCCTMP}/est | tee -a ${SCCTMP}/eload
echo " ===============================================================================
        Total                                                        ${n} --> $f  Mw " |tee -a  ${SCCTMP}/eload
_PRT ${SCCTMP}/eload
                                          

echo "  Date $date6_asc
        data        Middle ( SS & DP )               CB descr.                    Amp.

 ==================================================================================== " |tee  ${SCCTMP}/mload
grep  "M-"  ${SCCTMP}/bb|sort -k2 -u >${SCCTMP}/mdl
dcc_ss_replace -a ${SCCTMP}/mdl | tee -a ${SCCTMP}/mload
echo " ===============================================================================
        Total                                                        ${m} --> $u  Mw " |tee -a  ${SCCTMP}/mload
_PRT ${SCCTMP}/mload


echo "   Date $date6_asc
        data        West ( SS & DP )               CB descr.                    Amp.

 ==================================================================================== " |tee  ${SCCTMP}/wload
grep  "W-"  ${SCCTMP}/bb|sort -k2 -u >${SCCTMP}/wst
dcc_ss_replace -a ${SCCTMP}/wst | tee -a ${SCCTMP}/wload
echo " ===============================================================================
        Total                                                        ${g} --> $h  Mw " |tee -a  ${SCCTMP}/wload
_PRT ${SCCTMP}/wload

;;

*) break ;;
esac

ls -Ftl /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/$calcfile
ls -Ftl /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile}
read fncp?" Do you want to permentaly copy these files to /home/sis/REPORTS/Temporary/Eng_EHAB/
    [y]/n >> "
case v${fncp} in
v|vy|vY|vyes|vYes|vYES)
echo $date1_asc | awk 'FS="/"{print "/home/sis/REPORTS/Temporary/Eng_EHAB/Cutoff_Load/"$1"_"$2}' |read out_dir

if [ ! -d $out_dir ]
then
mkdir $out_dir
fi
cp /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${calcfile} $out_dir
cp /home/sis/REPORTS/Temporary/Eng_EHAB/tmp/${realfile} $out_dir

;;
esac

done

 



