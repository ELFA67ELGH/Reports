#! /bin/ksh
##############################################################
#
#
#
###############################################################
. $SCCROOT/aedc_SCC_functions
TMPDIR=/tmp/scc/davg
rm -f ${TMPDIR}/ss_cb_${DP}
HIS_DIR=/home/sis/REPORTS/Wednesday_OUTSS_max_value

if [[ ! -d ${TMPDIR} ]]
then
mkdir ${TMPDIR}
fi

Get_no (){
if [[ -z $1 ]]
then
echo "Sorry You've to set true ${val}"
exit
fi  
}
#===================================================================================================
do_val() {
echo ${ct1}|awk 'FS="."{print $2}'|read CT
echo ${ct1}|awk 'FS="."{print $1}'|read DP
 while read ln
 do
			date=""
			val=""
echo ${ln}|awk '{print substr($1,1,7)}'|read _dir
echo ${ln}|sed "s-${HIS_DIR}/${_dir}/--"|
awk 'FS="_"{print substr($3,1,2)"/"$2"/"$1}'|read date
# echo " >>> CT=${CT} <<< "  
zcat ${HIS_DIR}/${_dir}/${ln} |grep  -w "${DP}"|grep "${CT}<HAVG@"|
awk -v   PNT=${CT} -v DP=${DP} 'FS="@"{if(index($5,PNT)>0 && index($5,DP)>0)
{printf("%s %s\t%5.0f\t%s\n",$5, $11,$4,$7)}}'|
grep -v AVG_CURRENT|sort -u |awk '{print $2, $3 , $4}'|read val
if [ -z "$val" ]
then
val="--:-- 0 XXX"
fi
 
echo "${date}   ${val}" |awk '{printf("%-10s %-5s %5.0f %s\n",$1, $2,$3,$4)}'>>${TMPDIR}/val
done < ${TMPDIR}/day_list

}
#====================================================================================================
Get_date () {
mktime `date +"%Y/%m/%d:00:00:00"`|awk '{ print $1-86400}'|read asc_To
echo $asc_To |awk '{print $1-(7*24*60*60)}'|read asc_From
var_asctime $asc_From "%d/%m/%y"|read From1
var_asctime $asc_To "%d/%m/%y"|read To1
read From?"Please Enter From date ${From1} : "
if [ -z "${From}" ]
then
From=${From1}
fi
val=Date
Get_no ${From}   
read To?"Please Enter To   date ${To1} : "
if [ -z "${To}" ]
then
To=${To1}
fi
Get_no ${To} 
check_date
}

#=============================================================================================
check_date () { 
MAX=YES
	if [ `echo ${From}|awk 'FS="/"{print $3$2$1}'` -gt `echo ${To}|awk  'FS="/"{print $3$2$1}'` ]
	  then
	echo " Date Range not Acceptable 
Try Again ....
"
Get_date
else
if [ `echo ${From}|awk 'FS="/"{print $3$2$1}'` -eq `echo ${To}|awk  'FS="/"{print $3$2$1}'` ]
then

MAX=NO
  	fi
fi
day_list
}

#================================================================================================

day_list () {
echo ${From}|awk 'FS="/"{print "20"$3"/"$2"/"$1":00:00:00"}'|read from
echo ${To}|awk 'FS="/"{print "20"$3"/"$2"/"$1":00:00:00"}'|read to
mktime ${from}|read asc_from
mktime ${to}  |read asc_to
var_asctime ${asc_from} '%A' |read DOW
var_asctime ${asc_to} '%A' |read DOW2
fo=${asc_from}

while [ ${fo} -le ${asc_to} ]
	do
	var_asctime ${fo} "%Y_%m_%d.ld.Z"
	echo ${fo}|awk '{print $1+86400}'|read fo
	done >${TMPDIR}/file_list
ls -1 ${HIS_DIR}/*|grep .ld.Z|sed "s-${HIS_DIR}/--"|grep -v found |sort >${TMPDIR}/ex_file_list
com="comm -23 ${TMPDIR}/file_list ${TMPDIR}/ex_file_list"
com1="comm -12 ${TMPDIR}/file_list ${TMPDIR}/ex_file_list"
${com1} >${TMPDIR}/day_list

if [[ ! -z `${com}` ]]
then
echo "Days list not exist:"
${com}|awk '{print substr($1,9,2)"/"substr($1,6,2)"/"substr($1,1,4)}'|awk '{printf("%s\t",$1)}'|fold -91
echo
echo "----------------------------------------------------------------"
read ans?"would like to continue anyway press < CR > :"
	if [[ -z ${ans} ]]
	then
	echo "
Days Report will be for :
=========================
"
	${com1}|awk '{print substr($1,9,2)"/"substr($1,6,2)"/"substr($1,1,4)}'|awk '{printf("%s\t",$1)}'|fold -91
echo "
----------------------------------------------------------
"
      else
	break
      fi 
fi
}

#==============================================================================

Get_DP (){
read DPn?"Please Enter Which SSs or DPs  ( W-SS1 E-DP13 or W-SS or M-DP ): "
echo ${DPn}|awk '{print toupper($0)}'|read DPn
echo ${DPn}|awk '{print substr(toupper($0),1,1)}'|read DPS1
echo ${DPn}|awk '{print substr(toupper($0),3,2)}'|read rep 

case ${DPS1} in
E)dcc=East;;
M)dcc=Middle;;
W)dcc=West ;;
*)dcc="";;
esac

if [[ -z ${DPn} || -z `echo ${DPn} |grep -i -e DP -e SS`  ]]
then
echo "Sorry U've to Enter val ....."
sleep 2
exit
fi
	if [[ -z `echo ${DPn} |grep [1-9]` ]]
	then
    case ${DPn} in
   	SS|DP) SS_ls="E-${DPn} M-${DPn} W-${DPn}"
		ls="${SS_ls}"
		echo All Alexandria  ${DPn}s will be Reported ......
		CON="All Alexandria  ${DPn}s" ;;
	W-SS|M-SS|E-SS|W-DP|M-DP|E-DP) SS_ls="${DPn}"
		echo All ${dcc} ${rep} will be Reported .......
		CON="All ${dcc} ${rep}"
		ls="${SS_ls}" ;;
	esac
rm -f ${TMPDIR}/ss_dp_ls
#echo ${ls}   ls 
grep -w NAME ${src_file} |grep "${ls}."|awk '{print $4}'|awk 'FS="." {print $1}'|
sed 's/N//;s/P://;s/-T5//;s/E$//'|sort -u  >>${TMPDIR}/ss_dp_ls
no_CT="Y"
else
  rm -f  ${TMPDIR}/ss_dp_ls
if [ `echo   ${DPn} |awk '{print NF}'` -eq 1 ]
then
no_CT="N"
DP=${DPn}
echo ${DP} >${TMPDIR}/ss_dp_ls
else
for dp in ${DPn} 
	do
	echo $dp |grep -i -e [W,E,M]"-SS" -e [W,E,M]"-DP"|
	awk '{print toupper($1)}'>> ${TMPDIR}/ss_dp_ls
        awk '{printf ("%s " ,$1)}'  ${TMPDIR}/ss_dp_ls| read CON
	done
no_CT="Y"
fi
fi
}
#========================================================

do_ct(){
grep -w NAME ${src_file}| grep -e "${DP}\." -e "${DP}N\." -e "${DP}-T5\."|
awk '{print $4}'|awk 'FS="." {print $1"."$2}'|sed 's/P://;s/<HAVG//'|sort -u > ${TMPDIR}/ss_cb_${DP}
#echo no_CT $no_CT

if [[ ${no_CT} = N ]]
then
cat ${TMPDIR}/ss_cb_${DP}| awk '{printf("%s " ,$1)}'| read  CTA
read CT_NOs?"  Please CTA #  [ ${CTA}  ]  : > "
 if [[ ! -z ${CT_NOs} ]]
then
for CT_NO in  ${CT_NOs}
     do
	if [[ -z `echo ${CTA}|grep ${CT_NO}` ]]
	then 
	echo "CTA # ${CT_NO} isn't exist in $type file "
	else
	echo ${CT_NO} >>${TMPDIR}/ss_cb_${DP}
	fi
    done
else 
no_CT="Y"
  fi
fi
}

#========================================================================

Do_ss_cb_check(){
if [  ! -s  ${TMPDIR}/ss_cb_${DP} ]
	then
	echo "no CT for ${DP} in ${type} will be reported "
	break
	
#else
# awk '{printf("%s " ,$1)}' ${TMPDIR}/ss_cb_${DP}  | read ss_cb
fi	
}


#####################################################
# Loop Begin					    #
#####################################################

rm -f ${TMPDIR}/DHAVG
rm -f ${TMPDIR}/DHAVG2

while true
do
clear
CT_NO=""
echo "


	Main Feeder Daily Max Load Report
				 ( using Hourly Average values )
	_________________________________

   	1) Incoming Load report

	2) Outgoing load report
	
	3) Both I/O
"
read sel?"  Your choice  : "
 if [[ -z ${sel} ]]
  then
    break
  fi
   case ${sel} in
                                       
	1) filter="-e AVG_CURR" 
           src_file="/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_HAVG_in_??_AMP.dat"
	   type="Incoming Feeder" 
           ;;

	2) filter="-v AVG_CURR" 
           src_file="/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_HAVG_out_??_AMP.dat" 
	   type="Outgoing Feeders" 
          ;;
	
	3) filter="-e AVG_CURR -e CT" 
          src_file="/aedc/data/dbgen/SCC/SCC_ACC/SCCacc_HAVG_*_??_AMP.dat"
	  type="Incoming/Outgoing Feeders" 
          ;;

	*) echo Wrong command, try again
	break
        ;;
	
        esac
CT_NO=""
	Get_date
no_CT="N"
	Get_DP


echo "
 	  ${type} Max. Load Report for ${CON}"|tee   ${TMPDIR}/DHAVG



if [[ ${MAX} = YES  ]]
then
echo "	    During ${DOW} ${From}  -> ${DOW2} ${To}  
	------------------------------------" |tee  -a ${TMPDIR}/DHAVG
else

echo "	    During ${DOW} ${From}    
	------------------------------------" |tee  -a ${TMPDIR}/DHAVG
fi


 while read DP
 do
do_ct
Do_ss_cb_check

#=============================================================================
#sed 's/N//;s/P://;s/-T5//;s/<HAVG//;s/CT//'

######Have Tobe Modified  Abeer 2 Aug 2012


grep -w NAME ${src_file}|grep -v "!"| grep -e "${DP}\." -e "${DP}N\." -e "${DP}-T5\." -e "${DP}E\."|
awk '{print $4}'|awk 'FS="." {print $1"."$2}'|
sed 's/P://;s/<HAVG//'|sort -u > ${TMPDIR}/ss_cb_${DP}

awk 'FS="!"{print $1}' /aedc/cnf/scc/DCC_SS_DP | grep -w ${DP} |
head -1|awk 'FS="\t"{print $2,$3,$4,$5}'|read dp_des
echo "

  >>  ( $dp_des )  ${rep} <<
****************************************"|tee -a  ${TMPDIR}/DHAVG 
cnt=1
cat ${TMPDIR}/ss_cb_${DP}|grep CTA|sort -n  -tA -k2 >${TMPDIR}/ss_cb_${DP}1
cat ${TMPDIR}/ss_cb_${DP}|grep CTK|sort -n  -tK -k2>>${TMPDIR}/ss_cb_${DP}1

echo  "
select rtrim(C0003_group_name)+'.'+rtrim(C0007_point_name) +'@'+C0007_point_desc 
from T0007_point where 
rtrim(C0003_group_name)+'.'+rtrim(C0007_point_name) like '%${DP}%CB%' 
go"|isql -Udbu -Pdbudbu |grep @|sed 's/CB/CT/g'>${TMPDIR}/CT_DESC

cat ${TMPDIR}/ss_cb_${DP}1| while read ct1
do
cp /dev/null ${TMPDIR}/val

echo ${ct1}|awk 'FS="."{print $2}'|sed 's/CT[A,K]//'|read ct
echo ${ct1}|awk 'FS="."{print $1}'|read DP
cat ${TMPDIR}/CT_DESC|grep  CT[A,K]${ct}@|grep "${DP}\."|awk 'FS="@"{print $2}'|sed 's/CT AMPS //;s/CT //'|read acc_desc 
#echo "${ct})[ ${acc_desc} ] " |tee ${TMPDIR}/temp_DHAVG_${cnt}_t


if [[ ${MAX} = YES  ]]
then
echo "
${ct})[ ${acc_desc} ] " |tee -a ${TMPDIR}/DHAVG
echo "_____________________________"|tee -a ${TMPDIR}/DHAVG
sort ${TMPDIR}/day_list > ${TMPDIR}/day_list1
mv ${TMPDIR}/day_list1  ${TMPDIR}/day_list
do_val
#cat ${TMPDIR}/val |tee  ${TMPDIR}/temp_DHAVG_${cnt}
cat ${TMPDIR}/val |tee -a  ${TMPDIR}/DHAVG
echo "==========================="|tee -a ${TMPDIR}/DHAVG


sort -r -n -k3  ${TMPDIR}/val  |head -1|read HIH
echo Max ${HIH} |tee -a ${TMPDIR}/DHAVG
else
sort ${TMPDIR}/day_list > ${TMPDIR}/day_list1
mv ${TMPDIR}/day_list1  ${TMPDIR}/day_list
do_val
cat ${TMPDIR}/val |awk '{print $2 ,$3}'| read val
echo "${ct})[ ${acc_desc} ]@${val} "|awk 'FS="@"{printf("%-30s\t%20s\n"),$1,$2}'|tee -a ${TMPDIR}/DHAVG
fi


#if [[ ${MAX} = YES  ]]
#then
#echo "==========================="
#sort -r -n -k3  ${TMPDIR}/val  |head -1 |tee -a ${TMPDIR}/temp_DHAVG_${cnt}
#sort -r -n -k3  ${TMPDIR}/val  |head -1 |tee -a ${TMPDIR}/DHAVG
#fi
#echo ${cnt} |awk '{print $1+1}'|read cnt

#if [ $cnt -eq 3 ]
#then
#paste  ${TMPDIR}/temp_DHAVG_1_t ${TMPDIR}/temp_DHAVG_2_t  >> ${TMPDIR}/DHAVG
#echo " Day Time Amp Time Amp" |awk '{printf("%-10s  %-5s  %s | %-5s  %s\n",
#$1 ,$2, $3 , $4, $5)}'>>  ${TMPDIR}/DHAVG
#echo >>  ${TMPDIR}/DHAVG

#paste  ${TMPDIR}/temp_DHAVG_1 ${TMPDIR}/temp_DHAVG_2 |awk '{
#printf("%-10s  %-5s  %s |   %-5s  %d\n",$1 ,$2, $3 , $5, $6)}'>>  ${TMPDIR}/DHAVG
#rm -f ${TMPDIR}/temp_DHAVG_1 ${TMPDIR}/temp_DHAVG_2
#cnt=1
#echo "-----------------------------------------">>${TMPDIR}/DHAVG
#fi
  done  

#if [ -s ${TMPDIR}/temp_DHAVG_1  ]
#then
#echo " Day Time Amp" |awk '{printf("%-10s  %-5s  %s\n",$1 ,$2, $3)}'>> ${TMPDIR}/DHAVG
#echo "========================================="|tee -a  ${TMPDIR}/DHAVG
#cat ${TMPDIR}/temp_DHAVG_1  >> ${TMPDIR}/DHAVG
#rm -f ${TMPDIR}/temp_DHAVG_1
#fi
done < ${TMPDIR}/ss_dp_ls

dcc_ss_replace -i  ${TMPDIR}/DHAVG |sed 's/ABIS/( ABIS )/g' >> ${TMPDIR}/DHAVG2  
read samary?"    Do you want to print 
 A ) All
 S ) Samary
   choice (<CR> for all) >> "

case `echo v$samary|cut -c1-2|awk '{print toupper($1)}'` in
VS)
awk '{if (substr($0,3,1) != "/") {print $0}}' ${TMPDIR}/DHAVG2 |
grep -v -e "===" -e "___"|
awk 'FS="["{if (length($2) > 0) {printf("%-40s\t",$0)}
                          else  {print $0}}' > ${TMPDIR}/DHAVG_sumary

_PRT ${TMPDIR}/DHAVG_sumary

;;

*)

_PRT ${TMPDIR}/DHAVG2 

;;

esac

break
done
