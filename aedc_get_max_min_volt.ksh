#!/bin/ksh

. $SCCROOT/aedc_SCC_functions
function prep_DP_fl {
cat /aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_DP_VOLT.dat > $SCCTMP/15MIN_in_DP_VOLT
#grep -w NAME /aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat|grep [-]DP |grep -v "E-DP13"|grep -v "M[-]DP22" |
# awk '{print $3}' | while read acnt
#do
#grep -p "$acnt" /aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat |grep -p -v SPARE >> $SCCTMP/15MIN_in_DP_VOLT
#done
}

function prep_infl_list {
mktime `echo $date1_asc | cut -f1 -d ":"`:00:00:00 | read d1
mktime `echo $date6_asc | cut -f1 -d ":"`:00:00:00 | read d2
d=$d1
print -n "" > $SCCTMP/infl_list
while [ $d -le $d2 ]
do
var_asctime $d '/home/sis/REPORTS/Dly_MinMaxVOLT/%Y_%m/%Y_%m_%d.Vlt.Z' |read fl 
if [ -f $fl ]
  then
  echo $fl >> $SCCTMP/infl_list
  else
  echo " >> $fl not exists "
  fi
d=`expr $d + 86400`
done
}

function check_acc_lst {
if [[ ! -s  $SCCTMP/accts ]]
then
echo "No Account Match selection .... Try Again
"
exit
fi
}

function rate {
echo "select C0003_group_name,C0007_point_name
from T0007_point
where C0007_point_id=(
select C0401_source_id_int from T0401_accounts
where C0401_name='$acct')
go"|isql -U dbu -P dbudbu | head -3 |tail -1 | read src

grep -p $acct  $In_Fl | grep DESCRIPTION|awk 'FS="FOR"{print toupper($2)}'|awk '{printf("%-30s\n",$0)}'|read desc 
echo $acct|awk 'FS="."{print $1}' |read ss
echo $acct|awk 'FS="."{print $2}'|awk 'FS="<"{print $1}'| read pta
grep "$src" /aedc/cnf/scc/PTnot11KV|read not11
if [ -z "$not11" ]
then
rat=10.5
else
grep "$src" /aedc/cnf/scc/PTnot11KV| awk '{print $3}' | read rat
fi

if [ -z  "`grep $acct /aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat|grep -v -p SPARE`" ] 
then
echo "$ss"."$desc"|read  desc
fi
}

function peak_val {
grep "NAME" $In_Fl| awk '{print $3}'|grep  ${selection}> $SCCTMP/accts
check_acc_lst
echo "$ofset_titl	$location ( Max & Min Voltage )
$ofset_titl			During	$titel_dt
$ofset_titl		_____________________________________________
$ofset_titl		  Max Value			    Min Value 
$ofset_titl	 Val	Dev%	$dt_frmt	  Val	Dev%	$dt_frmt 
$ofset_titl	_____________________________    ____________________________" > ${Out_Fl}

while read acct  		# from $SCCTMP/accts #
do
case $data_src in
1)
echo "
declare @aid  int
select @aid = (select C0401_aid from T0401_accounts where C0401_name = '$acct') 
select str(C0432_value_r,5,1) ,
 $syb_dt
substring(convert(char(8),dateadd (second, C0432_date,'${offset}'),108),1,5) 
from T0432_data
where C0401_aid = @aid
and C0432_date between $date1_sec and $date2_sec
/* and C0432_value_r > 1 */
and C0432_status & 8 = 8 and ( C0432_status & 4 = 0 or C0432_status & 2 = 2 ) 
go"|isql -Udbu -Pdbudbu|sort -n|grep ":" > $SCCTMP/values
tail -1 $SCCTMP/values|awk 'OFS="\n"{print $1,$2}' | { read maxvolt ; read maxdt ; }
head -1 $SCCTMP/values|awk 'OFS="\n"{print $1,$2}' | { read minvolt ; read mindt ; }
if [ "$maxvolt" -le 1 ]
then
maxvolt=0
fi

if [ "$minvolt" -le 1 ]
then
minvolt=0
fi

;;
2)
filter_acc_date_range -n $acct > /dev/null
awk '$3>5{print substr($3,1,4),$2,$5}' $SCCTMP/Filter_acc |
   grep -e " 8$" -e " 9$" -e " 12$" -e " 14$" -e " 40$" -e " 44$" -e " 136$" -e " 140$" -e " 168$" -e " 172$" |
   sort -n > $SCCTMP/values1
head -1 $SCCTMP/values1 >  $SCCTMP/values2
tail -1 $SCCTMP/values1 >>  $SCCTMP/values2
print -n "" > $SCCTMP/values3
echo $dt_frmt | sed 's/mm/%m/;s/dd/%d/;s/HH/%H/;s/MM/%M/' | read dt_frmt1
print -n ` head -1 $SCCTMP/values2 | awk '{printf("%s@",$1)}'` >> $SCCTMP/values3
var_asctime `head -1 $SCCTMP/values2 | awk '{print $2}'` "$dt_frmt1" >> $SCCTMP/values3 
print -n ` tail -1 $SCCTMP/values2 | awk '{printf("%s@",$1)}'` >> $SCCTMP/values3
var_asctime `tail -1 $SCCTMP/values2 | awk '{print $2}'` "$dt_frmt1" >> $SCCTMP/values3
sed 's/@/ /'  $SCCTMP/values3 > $SCCTMP/values
tail -1 $SCCTMP/values|awk 'OFS="\n"{print $1,$2}' | { read maxvolt ; read maxdt ; }
head -1 $SCCTMP/values|awk 'OFS="\n"{print $1,$2}' | { read minvolt ; read mindt ; }
;;
3)
  while read fl
  do
  zcat $fl | grep "$acct" | awk 'FS="@"{printf("%s %4.1f %s %4.1f %s\n",$7,$4,$8,$12,$13)}'
  done < $SCCTMP/infl_list > $SCCTMP/values

awk  -v d=${date1_asc}  -v d1=${date6_asc} '{
T=substr($1,7,4)"/"substr($1,4,2)"/"substr($1,1,2)":"$3":00"}{if(T>=d && T<=d1)print $0}' $SCCTMP/values >$SCCTMP/values1
mv $SCCTMP/values1 $SCCTMP/values


sort -n -k2 $SCCTMP/values | tail -1 | awk 'OFS="\n"{print $2,substr($1,4,2)"/"substr($1,1,2)":"$3}' |
{ read maxvolt ; read maxdt ; }



awk '$4>5{print $0}' $SCCTMP/values | sort -n -k4 | head -1 | awk 'OFS="\n"{print $4,substr($1,4,2)"/"substr($1,1,2)":"$5}' |
	 { read minvolt ; read mindt ; }
;;
esac

if [ "$maxvolt" -le 1 ]
then
maxvolt=00.0
fi

if [ "$minvolt" -le 1 ]
then
minvolt=00.0
fi

maxdt="`echo $maxdt | sed 's/T/ /g'`"
mindt="`echo $mindt | sed 's/T/ /g'`"
rate
#if [ ! -z "$maxvolt" ]
if [[ ! -z "$maxvolt" && "$maxvolt" -gt 1 ]]
then
echo "$rat $maxvolt $minvolt" | 
    awk '{printf("%3.1f\n %3.1f\n",100*($2-$1)/$1,100*($3-$1)/$1)}' | 
    { read maxdev ; read mindev ; }
maxvolt=`echo $maxvolt|awk '{printf("%4.1f\n",$1)}'`
minvolt=`echo $minvolt|awk '{printf("%4.1f\n",$1)}'`
maxdev=`echo $maxdev|awk '{printf("%4.1f\n",$1)}'`
mindev=`echo $mindev|awk '{printf("%4.1f\n",$1)}'`



   if [ `echo $maxdev |sed 's/-//'` -lt 5 ]
   then
   max=`echo "$maxvolt 	${maxdev}	$maxdt"`
   #else
   #if [ `echo $maxdev |sed 's/-//'` -gt 50 ]
   #then
   #max="---- Unreasonable data ----"
   else
   max=`echo "${maxvolt}	(${maxdev})	$maxdt "`
   #fi
   fi

	if [ `echo $mindev |sed 's/-//'` -lt 5 ]
	then
	min=`echo "$minvolt 	${mindev}	$mindt"`
	#else
	#if [ `echo $mindev |sed 's/-//'` -gt 50 ]
	#then
	#min="---- Unreasonable data ----"
	else
	min=`echo "${minvolt}	(${mindev})	$mindt"`
	#fi
	fi
else
min="00.0	----	      -----"
max="00.0	----	      -----"
fi

#if [ $maxdev="XXX" ]
#then
#max="$maxvolt	$maxdev	      -----"
#fi

#if [ $mindev="---" ]
#then
#min="$minvolt	$mindev	      -----"
#fi

echo "$desc	$max	| $min"|tee -a $SCCTMP/subFinal
done  < $SCCTMP/accts
sort $SCCTMP/subFinal > $SCCTMP/subFinal1
mv $SCCTMP/subFinal1 $SCCTMP/subFinal
echo
awk '/E-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort  -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' > $SCCTMP/ss_list
awk '/M-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort  -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' >> $SCCTMP/ss_list
awk '/W-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort  -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' >> $SCCTMP/ss_list
m=1
while read ss		# from $SCCTMP/ss_list #
do
echo "\n$m)$ss\n=====================" >> ${Out_Fl}
grep "${ss}\." $SCCTMP/subFinal | sed "s/${ss}.//" | sed "s/BAR/TR/"|sed "s/SEC/TR/"|sed "s/FEDR/TR/"  >> ${Out_Fl}
echo "_________________________________________________________________">> ${Out_Fl}1
m=`expr $m + 1`
done < $SCCTMP/ss_list
dcc_ss_replace -a ${Out_Fl}|sed "s/ABIS/$ABIS/g" >${Out_Fl}1
mv ${Out_Fl}1 ${Out_Fl}
cat ${Out_Fl}
_PRT ${Out_Fl}
#cp -i ${Out_Fl} /home/sis/REPORTS/DAILY_Max_Min_VOLT/

}

function peak_hr {
#grep -w "NAME" $In_Fl | awk '{print $3}' |grep -e [-]SS -e [-]DP -e M[-]SEMOH > $SCCTMP/accts

grep -v -p SPARE $In_Fl|grep -w "NAME" | awk '{print $3}' |grep ${selection} > $SCCTMP/accts
check_acc_lst
hr_lst0="04 12 21"
read hr_lst?" Enter 3 peak hours (<CR> for default [04 12 21]) >> "
if [ -z "$hr_lst" ]
then
hr_lst="$hr_lst0"
fi
echo $hr_lst|awk '{printf ("%s\n%s\n%s\n",$1,$2,$3)}'|{ read hr1 ; read hr2 ; read hr3 ; }

echo "             $TTT
		$titel_dt At Hours [ $hr_lst ]
		_____________________________________________
$ofset_titl	    at $hr1 	   at $hr2 	    at $hr3
$ofset_titl	 kV	Dev%	  kV 	Dev%	  kV 	Dev% 
$ofset_titl	_______________  _____________	 _____________" > ${Out_Fl}

data_src_select 

while read acct  		# from $SCCTMP/accts #
do
case $data_src in
1)
echo "
declare @aid  int
select @aid = (select C0401_aid from T0401_accounts where C0401_name = '$acct') 
select str(C0432_value_r,4,1) ,
substring(convert(char(8),dateadd (second, C0432_date,'${offset}'),108),1,5) 
from T0432_data
where C0401_aid = @aid
and C0432_date between $date1_sec and $date2_sec
/* and C0432_value_r > 1 */
and C0432_status & 8 = 8 and ( C0432_status & 4 = 0 or C0432_status & 2 = 2 ) 
go"|isql -Udbu -Pdbudbu|grep -e " ${hr1}:00"  -e " ${hr2}:00" -e " ${hr3}:00" > $SCCTMP/values
grep " ${hr1}:00" $SCCTMP/values | awk '{print $1}' | read val1
grep " ${hr2}:00" $SCCTMP/values | awk '{print $1}' | read val2
grep " ${hr3}:00" $SCCTMP/values | awk '{print $1}' | read val3
;;
2)
filter_acc_date_range -n ${acct} > /dev/null
awk '$3>5{print substr($3,1,4),$2,$5}' $SCCTMP/Filter_acc |
grep -e " 8$" -e " 9$" -e " 12$" -e " 14$" -e " 40$" -e " 44$" -e " 136$" -e " 140$" -e " 168$" -e " 172$" > $SCCTMP/values1
mktime `echo $date1_asc $hr1|awk '{print substr($1,1,11)$2":00:00"}'`|read hr1_sec
mktime `echo $date1_asc $hr2|awk '{print substr($1,1,11)$2":00:00"}'`|read hr2_sec
mktime `echo $date1_asc $hr3|awk '{print substr($1,1,11)$2":00:00"}'`|read hr3_sec
grep $hr1_sec $SCCTMP/values1 | awk '{print $1}' | read val1
grep $hr2_sec $SCCTMP/values1 | awk '{print $1}' | read val2
grep $hr3_sec $SCCTMP/values1 | awk '{print $1}' | read val3
;;
esac

if [ "$val1" -le 1 ]
then
val1=00.0
fi
if [ "$val2" -le 1 ]
then
val2=00.0
fi
if [ "$val3" -le 1 ]
then
val3=00.0
fi

rate
n=1
for vval in v$val1 v$val2 v$val3
do
val=`echo $vval | sed 's/v//'`
if [ ! -z "$val" ]
then
echo "$rat $val" | awk '{printf("%3.1f\n",100*($2-$1)/$1)}' | read dev
if [ `echo $dev |sed 's/-//'` -ge 5 ]
then
if [[ `echo $dev |sed 's/-//'` -gt 50 && $val -gt 0 ]]
then
val="$val Unreas. "
dev="\b\b\b\b"
else
if [ `echo $dev |sed 's/-//'` -eq 100 ]
then
dev="---"
else
dev="(${dev})"
fi
fi
fi
echo "$val\n$dev" | { read val${n} ; read dev${n} ; }
else
echo "---\n---\n" | { read val${n} ; read dev${n} ; }
fi

n=`expr $n + 1`
done
echo "$desc	 $val1	$dev1	| $val2	$dev2	| $val3	$dev3" | tee -a $SCCTMP/subFinal
done  < $SCCTMP/accts
echo
awk '/E-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort -n -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' > $SCCTMP/ss_list
awk '/M-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort -n -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' >> $SCCTMP/ss_list
#awk '/W-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort -n -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' >> $SCCTMP/ss_list
awk '/W-/,FS="."{print $1}' $SCCTMP/subFinal | sed 's/SS/SP/' | sort -n -u -tP -k2 | grep -v "^$" | sed 's/SP/SS/' | grep "[0-9]" >> $SCCTMP/ss_list
awk '/W-/,FS="."{print $1}' $SCCTMP/subFinal | grep -v "[0-9]" | sort -u >> $SCCTMP/ss_list



while read ss		# from $SCCTMP/ss_list #
do
echo "
$m)$ss ${ofset_titl}\n===================" >> ${Out_Fl}
grep "${ss}\." $SCCTMP/subFinal | sed "s/${ss}.//" | sed "s/BAR/TR/"|sed "s/SEC/TR/"|sed "s/FEDR/TR/"  >> ${Out_Fl}
echo "______________________________________________________________________________">> ${Out_Fl}
m=`expr $m + 1`
done < $SCCTMP/ss_list
dcc_ss_replace -a ${Out_Fl}
sed '/[A-Z]*|/s/  |/|/' ${Out_Fl} |sed "s/ABIS/${ABIS}/"> ${Out_Fl}1
mv ${Out_Fl}1 ${Out_Fl}
#_PRT ${Out_Fl}
asc_print ${Out_Fl} -nH -1 -nd -B -F10 -p -nL
#cp -i ${Out_Fl} /home/sis/REPORTS/DAILY_Max_Min_VOLT/
}




#==========================
#	Start of Script
#==========================
rm -f $SCCTMP/subFinal
#echo "Jan 1 1970 `asctime 3600 |awk '{print $4}'|awk 'FS=":"{print $1}'`:00AM"|read offset
#echo "Jan 1 1970 `asctime 0 |awk '{print $4}'|awk 'FS=":"{print $1}'`:00AM"|read offset
enter_range 
#echo "date from  $date1_asc to   $date6_asc  " 
creat_rng_statment $date1_asc $date6_asc
mktime $date1_asc | read date1_sec
mktime $date6_asc | read date2_sec
asctime $date1_sec | awk '{print $1,$3,$2,$5}' | read dt1_titl
asctime $date2_sec | awk '{print $1,$3,$2,$5}' | read dt2_titl
if [ `expr $date2_sec - $date1_sec` -le 86400 ]
then
titel_dt="    $dt1_titl"
syb_dt="replicate('T',6)+"
dt_frmt="      HH:MM"
else
titel_dt="$dt1_titl to $dt2_titl"
syb_dt="substring(convert(char(10),dateadd (second, C0432_date,'${offset}'),111),6,5)+':'+ "
dt_frmt="mm/dd:HH:MM"
fi

while true 
do
clear
#sleep 10
 
selection=""

echo "	
        	    Voltage  Report 
                 $titel_dt
	           =======================

                
	1) Transformer Substation (SS)

	2) Distribution Point Feeders (DP)

	3) Max.&Min. Voltages for (SS) from [Dly_MinMaxVOLT] files
	
	4) Max.&Min. Voltages for (DP) from [Dly_MinMaxVOLT] files"
if [ `expr $date2_sec - $date1_sec` -le 90000 ]

then
echo "
	5) Transformer Substation (SS) for specific peak hrs

	6) Distribution Point Feeders (DP) for specific peak hrs"

fi
read ch?"
enter your choice >> "
if  [[ -z $ch ]]
then
echo "Bad Choice ... Try Again "
break
fi

read sel?"Select group list [ E M W , M-DP1 , W-SS,...] <CR> for all: "
rm  -f /tmp/scc/accts /tmp/scc/Final /tmp/scc/Final_desc /tmp/scc/ss_list /tmp/scc/subFinal 
if  [[ ! -z $sel ]]
then

echo $sel |awk 'OFS="\n"{print $1,$2,$3,$4,$5,$6,$7,$8}'|grep [A-Z]>/tmp/scc/list
cat /tmp/scc/list |while read arg1
do
echo $arg1 |awk '{print toupper($1)}'|read arg
if  [[ ! -z $arg ]]
then
if [ `echo $arg|wc -c` -eq 6 ]
then
selection="$selection -e ^${arg}[.]"
else
selection="$selection -e ^${arg}"
fi
fi
done
else
selection=^[A-Z]
fi

case $ch in
1)
In_Fl=/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat
Out_Fl=$SCCTMP/${rng_statment}_SSVoltPk
ofset_titl=""
ABIS="( ABIS )"
m=1
location="Substation Transformer"
data_src_select 
#grep "NAME" $In_Fl| awk '{print $3}'|grep  ${selection}> $SCCTMP/accts
peak_val
;;

2)
prep_DP_fl
In_Fl=$SCCTMP/15MIN_in_DP_VOLT
Out_Fl=$SCCTMP/${rng_statment}_DPVoltPk
ofset_titl="\t\t\t"
location="Distribution Point"
ABIS="ABIS"
m=1
data_src_select 
#grep "NAME" $In_Fl| awk '{print $3}'|grep  ${selection}> $SCCTMP/accts
peak_val
;;


3)
prep_infl_list
In_Fl=/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat
Out_Fl=$SCCTMP/${rng_statment}_SSVoltPkfl
ofset_titl=""
ABIS="( ABIS )"
m=1
data_src=3
#zcat `tail -1 $SCCTMP/infl_list` | awk 'FS="@"{print $2}' | grep ${selection} > $SCCTMP/accts
peak_val
;;

4)
prep_infl_list
In_Fl=$SCCTMP/15MIN_in_DP_VOLT
Out_Fl=$SCCTMP/${rng_statment}_DPVoltPkfl
ofset_titl="\t\t\t"
ABIS="ABIS"
m=1
data_src=3
#zcat `tail -1 $SCCTMP/infl_list` | awk 'FS="@"{print $2}' | grep ${selection} > $SCCTMP/accts
peak_val
;;

5)
In_Fl=/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_15MIN_in_SS_VOLT.dat
Out_Fl=$SCCTMP/${rng_statment}_SSVoltHr
ofset_titl=""
TTT="	SubStation Transforms Voltage "
ABIS="( ABIS )"
m=1
peak_hr
;;

6)
prep_DP_fl
In_Fl=$SCCTMP/15MIN_in_DP_VOLT
Out_Fl=$SCCTMP/${rng_statment}_DPVoltHr
#In_Fl=/aedc/data/dbgen/SCC/SCC_ACC/test
ofset_titl="\t\t\t"
ABIS="ABIS"
m=1
TTT="	  Distribution Feeders Voltage "
peak_hr
;;

*) echo "		Bad choice "  
exit
esac

read filt?"do you want to filter on -ve deviation ? [n] >> "
if [ -z "$filt" ]
then
filt=n
fi
case $filt in
y|Y|yes|YES|Yes)
#awk '{if (match($0,"|") ==0) {print $0}
#else
#if (match($0,"-[0-9]")!=0) {print $0}}' $Out_Fl | grep -p -e "-" -e "at" -e "Dev"> ${Out_Fl}_tmp
awk '{if ($4!="|") {print $0}
else
if (match($0,"-[0-9]")!=0) {print $0}}' $Out_Fl | grep -p -e "-" -e "at" > ${Out_Fl}_tmp
cat ${Out_Fl}_tmp
_PRT ${Out_Fl}_tmp
;;
esac
done
