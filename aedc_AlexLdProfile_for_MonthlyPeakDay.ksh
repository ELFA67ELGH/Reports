#!/bin/ksh
#-------------------------------------------------------------------------
# TITLE   : aedc_AlexLdProfile_for_MonthlyPeakDay.ksh
# PURPOSE : To determine the day ofpeak of Alex and report its load profile 
#	    hourly
#
#
# GROUP   : SCC
# AUTHOR  : Eman Aly  ( Alexandria Superviory Control Center )
# DATE    : 26 Oct 2008
#--------------------------------------------------------------------------

 . /aedc/etc/work/aedc/SCC/aedc_SCC_functions
 
mktime `date +'%Y/%m/%d:00:00:00'`|awk '{print $1-60*60*24}'|read yes_sec

 
clear
do_all (){

echo "
		Alexandria Load Profile 
		$PkDay_titel 
                $sub_titel		
   _________________________________________________________
  | Time    |              Alexandria load Profile          |
  |         |-----------------------------------------------| 
  |  hh:mm  |   MWatt   |   MVar    |   MVA     |    PF     |
  |_________|___________|___________|___________|___________|" |tee $SCCTMP/LdProf_outFl 

cat $SCCTMP/tm_val|awk -v pf="-" -v Mvar="-" '{if ( $2 !="-" && $3 !="-" && $3>$2 ) {
{ if ( $2 > Max ){Max=$2 ; hr=$1 ;Mvar=sqrt(($3^2)-($2^2));Mva=$3 ;pf=$2/$3}}
{printf("  | %5s   |  %7.1f  |  %7.1f  |  %7.1f  |  %7.3f  |\n",$1,$2,sqrt(($3^2)-($2^2)), $3, $2/$3 )}}
else
{printf("  | %5s   |  %7.6s  |  %7.6s  |  %7.6s  |  %7.5s  |\n",$1,$2,"-", $3, "-" )}}
END{printf("  |_________________________________________________________|\n  | Max Load At:\n  | %5s   |  %7.1f  |  %7.1f  |  %7.1f  |  %7.3f  |\n  |_________|___________|___________|___________|___________|\n",hr ,Max ,Mvar,Mva,pf)}'|
tee -a $SCCTMP/LdProf_outFl
echo $Note|tee -a $SCCTMP/LdProf_outFl
}

do_mw () {
echo "
		Alexandria Load Profile 
		$PkDay_titel 
                $sub_titel		
   ___________________________________
  | Time    |Alexandria load Profile |
  |         |------------------------| 
  |  hh:mm  |         MWatt          |
  |_________|________________________|" |tee $SCCTMP/LdProf_outFl 

cat $SCCTMP/tm_val|awk '{if ( $2 !="-" ) {
{ if ( $2 > Max ){Max=$2 ; hr=$1}}
{printf("  | %5s   |  %12.1f          |\n",$1,$2)}}
else
{printf("  | %5s   |  %12.6s          |\n",$1,"-" )}}
END{printf("  |__________________________________|\n  | Max Load At:\n  | %5s   |  %12.1f          |\n  |_________|________________________|\n",hr ,Max)}'|
tee -a $SCCTMP/LdProf_outFl

echo $Note|tee -a $SCCTMP/LdProf_outFl
}


echo " Your Selection :

	1) Profile of a specific day
	
	2) Profile of peak day in a specific month 
	"
	
read ch?"  Ur choice is : "	
 case $ch in
1)
var_asctime ${yes_sec} "%d/%m/%Y"|read sugg_day
read day?" Enter a day on the form < $sugg_day >  : "
if [ -z "$day" ] 
then 
day=$sugg_day 
fi

echo ${day} |awk 'FS="/"{print $3"/"$2"/"$1}'|read Day
mktime ${Day}:00:00:00 | read strt_sec
var_asctime $strt_sec "%A %d %B %C%y" | read PkDay_titel
sub_titel=""
echo "select C0401_aid from T0401_accounts where C0401_name = 'ALEX.TOTAL_MWA<HMAX'
go"|isql -Udbu -Pdbudbu | { read ; read ; read mw_acc_id ;}   
#mw_acc_id=8537
;;

2)
echo "$yes_sec"|awk '{print $1-30*60*60*24}'|read mon_sec 
var_asctime  $mon_sec "%m/%Y"|read sugg_mon
read mon?"  Enter a month on the form < ${sugg_mon} >  : "
if [ -z "$mon" ] 
then 
mon=$sugg_mon 
fi

echo $mon | awk 'FS="/"{printf("/home/sis/REPORTS/MONTHLY_MAX_VALUE/%s/%s_%s.ld.Z\n",$2,$2,$1)}' |read InFilePK

echo $mon|awk 'FS="20"{print$1$2}'|read mmyy

if [ ! -s  ${InFilePK} ]
then
echo "
${InFilePK} ( File does not exist)  .....
      
      Creating from DataBase....... "
      
echo "select C0401_aid from T0401_accounts where C0401_name = 'ALEX.TOTAL_MWA<HMAX'
go"|isql -Udbu -Pdbudbu | { read ; read ; read mw_acc_id ;}   

echo "
select C0434_value , C0434_date ,C0434_status from T0434_peak_data where C0401_aid=$mw_acc_id
and C0434_status & 8 = 8 and 
substring(convert(char(8),dateadd(second,C0434_date,'${offset}'),3),4,5)='$mmyy'
go"|isql -Udbu -Pdbudbu |sort -r -n -k 1|head -1| awk '{print $1"\n"$2}'| { read val ; read dd ; }
#echo $val $dd

	else
zcat ${InFilePK} | grep "ALEX.TOTAL_MWA" | grep -v MINIMUM | awk 'FS="@"{print $1"\n"$5}' | { read mw_acc_id ; read dd ; }
#zcat $InFilePK | grep "ALEX.TOTAL_MVA" | grep -v MINIMUM | awk 'FS="@"{print $1}' | read mva_acc_id
fi
var_asctime $dd "%A %d %B %C%y" | read PkDay_titel
var_asctime $dd "%C%y/%m/%d" | read PkDay
sub_titel="( `echo ${PkDay_titel}| awk '{print $3$4}'` PeakDay )"
Day=${PkDay}
;;
*)
 echo "Bad Choose .... "
 exit
esac

date1_asc="${Day}:00:00:00"
date6_asc="${Day}:23:59:59"

Note=""
echo $Day|awk 'FS="/"{print $1"_"$2}'|read Month
mktime $Day:00:00:00|read ascDay
var_asctime $ascDay 'CutOff%b%Y'|read Cutfile

##############CuttOff Add
if [ -s /home/sis/REPORTS/DAILY_MAX_VALUE/$Month/${Cutfile} ]
then
echo $Day|awk 'FS="/"{print $1"_"$2"_"$3}'|read day
	if [ ! -z `grep "^${day}" /home/sis/REPORTS/DAILY_MAX_VALUE/$Month/${Cutfile}` ]
	then
	grep "^${day}" /home/sis/REPORTS/DAILY_MAX_VALUE/$Month/${Cutfile}|awk '{print $2}'|read Cut
	echo ${Cut}
	Note="Note : + ${Cut} MW" 
	fi
fi

echo " 
===================================================  

	1) Load Mwatt Only
	
	2) Load [ Mwatt , Mvar , MVA , PF ] 
	"

read typ?" Select Profile Type :  "

read bdst?" Ignoring Value Status  ( y/n ) : "
if [ -z "${bdst}" ]
then
bdst="n"
fi

#Gd_Vl="8 9 10 12 13 14 40 44 46 136 137 140 142 168 172"
#echo "${Gd_Vl}" |awk  '{print "-v st1="$1, "-v st2="$2 ,"-v st3="$3,
#"-v st4="$4, "-v st5="$5 , "-v st6="$6 , "-v st7="$7,
#"-v st8="$8, "-v st9="$9 , "-v st10="$10 , 
#"-v st"11"="$11 ,"-v st"12"="$12 ,"-v st"13"="$13  ,"-v st"15"="$15}'|read STAT
 
filter_acc_date_range -i ${mw_acc_id} > /dev/null	       # out_file is /aedc/tmp/scc/aedc/ALEX_LD
mv /tmp/scc/aedc/Filter_pkacc  /tmp/scc/aedc/ALEX_LD

if [ "${bdst}" != "y" or "${bdst}" != "Y" ]
then
cat /tmp/scc/aedc/ALEX_LD |while read ln		      # from /aedc/tmp/scc/aedc/ALEX_LD
do
echo $ln |awk -v st=${bdst} 'OFS="\n"{ mw="-" ; mva="-"}
{if(( $7==8 || $7==9||$7==10 || $7==12|| $7==13 ||
$7==14 || $7==40|| $7==44 || $7==46 || $7==136 || $7==137  ||
$7==140|| $7==142 || $7==168 || $7==172 ) && $4 > 0 )
{mva=$4}
{if(( $6==8 || $6==9||$6==10 || $6==12|| $6==13 ||
$6==14 || $6==40|| $6==44 || $6==46 || $6==136 || $6==137  ||
$6==140|| $6==142  || $6==168 || $6==172 ) && $3 > 0 )
{mw=$3}}
{print $2, mw,mva}}'| { read tm ; read val ; read val_mva ; } 
echo `var_asctime $tm "%H:%M" ` ${val}  ${val_mva}
done  > ${SCCTMP}/tm_val 
else
echo "Ignoring Status ...."

cat /tmp/scc/aedc/ALEX_LD |while read ln			# from /aedc/tmp/scc/aedc/ALEX_LD
do
echo $ln |awk 'OFS="\n"{ mw="-" ; mva="-"}
{if($4 > 0 ){mva=$4}
{if( $3 > 0 )
{mw=$3}}
{print $2, mw,mva}}'| { read tm ; read val ; read val_mva ; } 
echo `var_asctime $tm "%H:%M" ` ${val}  ${val_mva}
done  > ${SCCTMP}/tm_val 

fi

 case $typ in
1)do_mw ;;
2)do_all ;;
*) exit
esac

#grep -v -p Alexandria $SCCTMP/LdProf_outFl 
_PRT $SCCTMP/LdProf_outFl


