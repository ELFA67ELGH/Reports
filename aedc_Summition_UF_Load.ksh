#!/bin/ksh

. /aedc/etc/work/aedc/SCC/aedc_SCC_functions


function loop1 {
rm -f new-list 
while read line
do
echo $line | awk '{printf("%s\n",$0)}'|read nam
grep "TC $nam " bb >> new-list
done < ufilist

}


function process {

cat new-list|awk 'FS="SCL SUCC MANUAL ENTRY"{print $1,$2}'|
awk 'FS="      D   "{print $1,$2}'|
awk 'FS="TC"{print $1,$2}'|
awk 'FS="ascsys[1-2]:"{print $1,$2}'|awk 'FS="_CB"{print $1}'|
awk '{print substr($0,2,70)}'|grep -e "E-" > est1
awk '{print substr($0,65,17)}' est1  > east

n1=0
while read line
do
echo $line |awk '{printf("%s\n",$0)}'|read n2
echo "${n1}  ${n2}"|awk '{print $1 + $2}'|read n1
done < east                       
echo " Total East = ${n1} "
echo $n1 |awk '{print $1/55 }'|read f
echo " Total East Mw = $f "

cat new-list|awk 'FS="SCL SUCC MANUAL ENTRY"{print $1,$2}'|
awk 'FS="      D   "{print $1,$2}'|
awk 'FS="TC"{print $1,$2}'|
awk 'FS="ascsys[1-2]:"{print $1,$2}'|awk 'FS="_CB"{print $1}'|
awk '{print substr($0,2,70)}'|grep -e "M-" > mdle1
awk '{print substr($0,65,17)}' mdle1 > middle

s1=0
while read line
do
echo $line |awk '{printf("%s\n",$0)}'|read s2
echo "$s1  $s2"|awk '{print $1 + $2}'|read s1
done < middle                      
echo "\n"
echo " Total Middle = ${s1} "
echo $s1 |awk '{print $1/55 }'|read u1
echo " Total Middle Mw = $u1 "

cat new-list|awk 'FS="SCL SUCC MANUAL ENTRY"{print $1,$2}'|
awk 'FS="      D   "{print $1,$2}'|
awk 'FS="TC"{print $1,$2}'|
awk 'FS="ascsys[1-2]:"{print $1,$2}'|awk 'FS="_CB"{print $1}'|
awk '{print substr($0,2,70)}'|grep -e "W-" > wst1
awk '{print substr($0,65,17)}' wst1 > west

g=0
while read line
do
echo $line |awk '{printf("%s\n",$0)}'|read r1
echo "$g  $r1"|awk '{print $1 + $2}'|read g
done < west                      
echo "\n"
echo " Total West = ${g} "
echo $g |awk '{print $1/55 }'|read h
echo " Total West Mw = $h "

echo "$g $s1 $n1"|awk '{print $1 + $2 + $3}'|read k
echo "\n"
echo " Total Amper = $k "
echo $k |awk '{print $1/55 }'|read p
echo "$p"|awk '{printf("%.2f",$1)}'|read p
echo "  `tput blink``tput bold` Total Mw = $p`tput sgr0` "

dcc_ss_replace -a est1  |sed 's/     //'|sed 's/     //'|sed 's/     //'|sed 's/     //'|sort -k1 -k2 > est

u=est
out

dcc_ss_replace -a mdle1 |sed 's/     //'|sed 's/     //'|sed 's/     //'|sed 's/     //'|sort -k1 -k2 > mdle

u=mdle
out

dcc_ss_replace -a wst1  |sed 's/     //'|sed 's/     //'|sed 's/     //'|sed 's/     //'|sort -k1 -k2 > wst

u=wst
out

}


function out {

	if [ $u = est ]
then 
R=EAST
z=e
n=${n1}
f=${f}
	fi


	if [ $u = mdle ]
then 
R=MIDDLE
z=m
n=${s1}
f=${u1}

	fi


	if [ $u = wst ]
then 
R=WEST
z=w
n=${g}
f=${h}

	fi

echo "$f"|awk '{printf("%.2f",$1)}'|read f

echo "
                     THE UNDER FREQUN. GROUP ${ug}	
                    -------------------------------      
  date        $R ( SS & DP )        CB Descr.                  Amp.

 ====================================================================== " > ${z}load
cat $u >> ${z}load
echo " ======================================================================
      total                                        ${n} --> ${f} Mw " >> ${z}load


#cat ${z}load 

#_PRT ${z}load

}


rm -f eload mload wload est mdle wst bb est1 mdle1 wst1 new-list east middle west stg1 ufilist 
rm -f report_UF1 report_UF2 report_UF3 report_UF4 report_UF5 report_UF6 report_UF7
while true
do

enter_his_date_range
mktime $date1_asc | read strt
mktime $date6_asc | read end

echo "
select C0439_alm_text from T0439_almhc where
C0439_alm_text like '%SCL SUCC MANUAL ENTRY%'
and C0438_date between $strt and $end
go" | isql -Udbu -Pdbudbu | grep -e "-SS" -e "-DP" > bb

clear

read stg?" Select Under Frequncy Stage ( UF1  UF2 UF3  UF4 UF5 UF6 UF7  ) >> "
echo $stg | awk '{printf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n"),$1,$2,$3,$4,$5,$6,$7}' |grep "UF" > stg1

while read line
do

rm -f wload mload eload  
grep $line /aedc/cnf/scc/Under_Freq/UF_lst | awk 'FS="@"{print $2}' > ufilist
echo ${line}
echo ${line}|read ug
loop1
process

cat wload >> mload
cat mload >> eload 
echo "                 \n [[  TOTAL Mw = $p ]] \n  " >> eload 
more eload

mv eload report_${ug}
done < stg1

ls report_* 

read fle?" select file to print >> "

_PRT $fle

rm -f eload mload wload est mdle wst bb est1 mdle1 wst1 new-list east middle west stg1 ufilist 
rm -f report_UF1 report_UF2 report_UF3 report_UF4 report_UF5 report_UF6 report_UF7 

read reply?"   Hit <CR> to continue    "
done
