#!/bin/ksh
. aedc_SCC_functions



do_rep() {
#IN_DIR=/home/sis/REPORTS/MONTHLY_MAX_VALUE/${yyyy}
IN_DIR=/SYBASE/sub_home/REPORTS/MONTHLY_MAX_VALUE/${yyyy}
cp /dev/null /aedc/tmp/scc/counter
for mm in 01 02 03 04 05 06 07 08 09 10 11 12
do
mktime ${yyyy}/${mm}/01:00:00:00|read Startmonth
var_asctime ${Startmonth} "%B"|read mon
echo "${mm} ${mon}" >> /aedc/tmp/scc/counter

nextmm=`expr $mm + 1`
expr `mktime ${yyyy}/${nextmm}/01:00:00:00` - 1 |read Endmonth
ln="${yyyy}_${mm}.ld.Z"
echo ${ln}|awk 'FS="_"{print $2}'|sed 's/\.ld//;s/\.Z//'|read Month

	if [ -s  ${IN_DIR}/${ln} ]
	then 
zcat ${IN_DIR}/${ln}|grep -e "${ALEX_NM}" -e "${ALEX}"|grep -v -e MINIMUM -e ${NOT_INC} |tail -1|awk '
FS="@"{printf("%.1f\n%d\n%s\n", $4, $5,$2)}'| { read Maxmw ; read Maxdt ; read NM ; }
zcat ${IN_DIR}/${ln}|grep -e "${ALEX_NM}" -e "${ALEX}"|grep -v -e MINIMUM  |tail -1|awk '
FS="@"{printf("%s\n",$2)}'| { read NM ; }

echo ${NM}|sed "s/ALEX.TOTAL_MWA_CutOff //;s/${ALEX_NM}//g"|read Cuttoff_val
var_asctime $Maxdt "%a %d %H:%M"|read Maxtm
zcat ${IN_DIR}/${ln}|
grep  -e "${ALEX_NM}" -e "${ALEX}"|
grep MINIMUM|tail -1|awk 'FS="@"{print  $4 ,$5}'|read Minval

echo ${Minval}|awk '{printf("%.1f\n%d\n", $1, $2)}'| { read Minmw ; read Mindt ; }
var_asctime $Mindt "%a %d %H:%M"|read Mintm
else
Cuttoff_val=""
 Maxmw="--"
 Maxtm="--- --  --:--"
 Minmw="--"
 Mintm="--- --  --:--"
	fi

echo "${Month}	$Maxmw 	$Maxtm $Minmw	$Mintm  ${Cuttoff_val} " 
done> /aedc/tmp/scc/VALUE_${yyyy}

echo "
        Alexadria Distribution load 
        Max. & Min   Mwatts ( ${STAT} )
        During  $yyyy
____________________________________________________________________________								    
              |    Maximum                 |    Minimum		    |   Cut
     Month    |   Mw      |   Time         |   Mw     | Time	    |	MWatt
____________________________________________________________________|_________"|tee  /tmp/scc/Yearly_Dist_Load_${yyyy}

join -a1 /aedc/tmp/scc/counter /aedc/tmp/scc/VALUE_${yyyy}|
awk '{printf(" %-12s |%9s  | %s %s %s   |  %5s  | %s %s %s |  %s\n",$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) }' > /tmp/scc/subout
cat /tmp/scc/subout|tee -a  /tmp/scc/Yearly_Dist_Load_${yyyy} 

echo "____________________________________________________________________________"|tee -a  /tmp/scc/Yearly_Dist_Load_${yyyy}

#grep -v "-" /tmp/scc/subout | sort -n -k3 | tail -1 | sed 's/   /Max:/' |
#awk '{print substr($0,1,42)}' |sed 's/  / /'| tee -a  /tmp/scc/Yearly_Dist_Load_${yyyy}
grep -v "-" /tmp/scc/subout | sort -n -k3 | tail -1| 
sed 's/^ /Max: /'|awk '{print substr($0,1,45)}' |sed 's/     / /'| tee -a  /tmp/scc/Yearly_Dist_Load_${yyyy}

grep -v "-" /tmp/scc/subout | sort -n -k9 | head -1 |sed  's/^ /Min: /'|
awk '{print substr($0,1,16),"\t\t       ",substr($0,45,28)}' |
sed 's/  / /'| tee -a  /tmp/scc/Yearly_Dist_Load_${yyyy}
echo "____________________________________________________________________________
"
_PRT /tmp/scc/Yearly_Dist_Load_${yyyy}
}

date +"%Y"|read currentyear
read yyyy?"Please Enter the Year <CR> ${currentyear} : "
if [ -z "$yyyy" ]
then
yyyy=${currentyear}
fi

read Cutoff?"Would U consider CuttOff load [ Y / N ]  : "

case ${Cutoff} in
n|N) ALEX=ALEX.TOTAL_MWA ; ALEX_NM="ALEX.TOTAL_MWA<HMAX" ; NOT_INC=ALEX.TOTAL_MWA_CutOff ;STAT="No Cutoff" ;; 
y|Y) ALEX=ALEX.TOTAL_MWA_CutOff  ; ALEX_NM="ALEX.TOTAL_MWA<HMAX" ; NOT_INC=balabalbalaaa ;STAT="With Cutoff";;
*) echo "Wrong Entry "
   exit
esac
do_rep



