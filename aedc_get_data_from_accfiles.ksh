#!/bin/ksh
#------------------------------------------------------------------------------------------------------------
# TITLE   : get_data_from_accfiles
# PURPOSE : to get the historical values of an account from daily account files saved in $HIS/
#
# GROUP   : IS
# AUTHOR  : Alaa Nagy
# DATE    : 18 May 2002
#-------------------------------------------------------------------------------------------------------------
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
function in_file_mode {
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# This function work on several accounts placed in a file which is named : $InFl
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
enter_range
data_src=2
#data_src_select
n=1
echo "  AccFileData					  AccName
  ==================				  ===============
  < All > for processing all accounts ............................" > $SCCTMP/out_fl_list
base_out_fl=$out_fl
for name in `awk '{printf("%s ",$1)}' $InFl` 
do
echo "
select C0401_description from T0401_accounts where C0401_name like  '${name}'
go"|isql -Udbu -Pdbudbu| { read ; read ; read DESC ; }
echo "Working with $name"
echo $name|sed 's/</_/'|read nm
out_fl=${base_out_fl}_acc${nm}
get_data
#process_data
n=`expr $n + 1`
done
echo "You have now the following AccFileData"
while true
do
cat $SCCTMP/out_fl_list
read out_fl?"chose file <CR> to exit >> "

case V${out_fl} in
V)exit ;;
VAll) process_alldata ;;
*)process_data ;;
esac

done
}

function get_data {
acc_prsnt_flag=true
echo "\n Please Wait.. [ extract data from files...]\n\n"
if [ "$data_src" = 2 ]
then
filter_acc_date_range -n "$name" > /dev/null
else
filter_acc_date_range -DB -n "$name" > /dev/null
grep -v -e "warning:" -e "^$" $outAccFl > ${outAccFl}_nowar
mv ${outAccFl}_nowar $outAccFl
#grep "warning:" $SCCTMP/Filter_acc
fi
case ${AccFlType} in
acc)
echo "DATA of $name @ ${DESC} 
between $date1_asc $date6_asc
===========================================
      date	 	value       status  
yyyy/mm/dd:hh:mm
===========================================" > $out_fl
awk '{print $2}' $outAccFl > $SCCTMP/sec_list 
print -n "" > $SCCTMP/time_list
while read sec
do
var_asctime ${sec} "%Y/%m/%d:%H:%M"  >> $SCCTMP/time_list
done < $SCCTMP/sec_list
awk '{printf("%6.2f\t%s\n",$3,$5)}' $outAccFl | awk '{printf(" %-10s  %s\n",$1,$2)}' > $SCCTMP/val_list
paste $SCCTMP/time_list $SCCTMP/val_list >>  $out_fl
echo "$out_fl		$name" >> $SCCTMP/out_fl_list
;;
pkacc)
echo "
 set nocount on
 declare @aid int
 declare @ass_nm char(25)
 select @aid = (select C0401_aid from T0401_accounts
                where C0401_name ='$name')
 if exists (select * from T0402_peak_account where C0401_aid=@aid)
 begin
 select @ass_nm = (select rtrim(C0003_group_name)+'.'+rtrim(C0007_point_name)
                   from T0007_point where C0007_point_id in (
                   (select C0402_assoc_pid from T0402_peak_account where C0401_aid=@aid)))
 select '(ass_point is '+ @ass_nm +')'
 end
 else
 select '(no ass_point)'
go"|isql -Udbu -Pdbudbu |head -3|tail -1 | read ass

echo "The DATA of $name $ass
between  $date1_asc $date6_asc
===================================================================
     date        value      ass	     status      ass	ocuur_time
yyyy/mm/dd:hr		   value       		status	hh:mm:ss
===================================================================" > $out_fl
awk '{print $2}' $outAccFl > $SCCTMP/sec_list 
awk '{print $5}' $outAccFl > $SCCTMP/ocu_sec_list 

print -n "" > $SCCTMP/time_list
while read sec
do
var_asctime $sec "%Y/%m/%d:%H" >> $SCCTMP/time_list
done < $SCCTMP/sec_list

print -n "" > $SCCTMP/ocu_time_list
while read sec
do
var_asctime $sec %H:%M:%S  >> $SCCTMP/ocu_time_list
done < $SCCTMP/ocu_sec_list

awk '{printf("%6.2f\t%6.2f\t\t%s\t%s\n",$3,$4,$6,$7)}' $outAccFl | awk '{printf(" %-10s %-10s %s\t%s\n",$1,$2,$3,$4)}'  > $SCCTMP/val_list

paste $SCCTMP/time_list $SCCTMP/val_list $SCCTMP/ocu_time_list >>  $out_fl
echo "$out_fl		$name" >> $SCCTMP/out_fl_list

;;
*)
echo " There is no such acc"
echo "
set nocount on
go
select C0401_name from T0401_accounts
where C0401_name like '%${AccNm}%'
go"|isql -U dbu -P dbudbu | grep "<" > $SCCTMP/other_acc
if [ -s $SCCTMP/other_acc ]
then
echo "\n\nPerhaps you want one of the folowing accounts"
cat $SCCTMP/other_acc
acc_prsnt_flag=false
fi
;;
esac
}


function process_alldata {
if [ "$acc_prsnt_flag" = "true" ]
then
#more $out_fl
  while true
  do
# data operation menu
# -------------------

echo "
  What do you want to do with this data ?
  	1 ) view all data
	..) Get peak value per account
		2a) Get max value per account
		2b) Get min value per account
		2c) Get both max & min values per account
		2d) Get daily max & min values per account ( day vs. min.,max. ; 1Paragraph/acc. )
	3 ) Filter on specific hr(s)
        4 ) Return
"
read ch?"  Your choice is <CR> to Exit >> "
case $ch in

  1)
  echo "  Warning : Max. number for acc is 7
	for reporting more 7 acc :you can run  {1 ) view all data}
			several times after editing the file $SCCTMP/out_fl_list each time "
  rm -f $SCCTMP/*Sub_ViewAll
  Sub_ViewList=""
  LineSep="======================="
  LineHead="    Date		"
  n=1
  grep "$base_out_fl" $SCCTMP/out_fl_list | awk '{print $2}' | cat -n > ${base_out_fl}_ViewAll
  grep "$base_out_fl" $SCCTMP/out_fl_list |
  	while read ln
	do
	echo $ln | awk 'OFS="\n"{print $1,$2}' | { read out_fl ; read acc ; }
	grep "^2" $out_fl | awk '{print $1,$2}' > ${out_fl}Sub_ViewAll
	Sub_ViewList="$Sub_ViewList ${out_fl}Sub_ViewAll"
	LineSep="${LineSep}========"
	LineHead="${LineHead}  (${n})	"
	n=`expr $n + 1`
	done
  echo "${LineSep}\n${LineHead}\nyyyy/mm/dd:hh:mm\n${LineSep}" >> ${base_out_fl}_ViewAll
  paste $Sub_ViewList | awk 'OFS="\t"{print $1,$2,$4,$6,$8,$10,$12,$14}' >> ${base_out_fl}_ViewAll
  cat ${base_out_fl}_ViewAll
  _PRT ${base_out_fl}_ViewAll
  ;;
2a) 
echo "
 ============================================
 Account Name            Value         Date
 ============================================" > ${out_fl}_accMax
awk '{if (NR>=4) {printf("%s ", $1)} }' $SCCTMP/out_fl_list | read fl_list
for Fname in $fl_list
do

echo $Fname  `awk '{if (NR>=7) {print $2"\t\t",$1} }' $Fname | sort -n | tail -1` | 
awk 'FS="_acc"{print $2}' |  awk '{print $1"\t"$2"\t"$3}' >> ${out_fl}_accMax
done 	# while read Fname
  cat ${out_fl}_accMax
 _PRT ${out_fl}_accMax
 ;;
 
 
2b) 
echo "
 ============================================
 Account Name            Value         Date
 ============================================" > ${out_fl}_accMin
awk '{if (NR>=4) {printf("%s ", $1)} }' $SCCTMP/out_fl_list | read fl_list
for Fname in $fl_list
do

echo $Fname  `awk '{if (NR>=7) {print $2"\t\t",$1} }' $Fname | sort -n | head -1` | 
awk 'FS="_acc"{print $2}' |  awk '{print $1"\t"$2"\t"$3}' >> ${out_fl}_accMin
done 	# while read Fname
  cat ${out_fl}_accMin
 _PRT ${out_fl}_accMin
 ;; 
 
2c) 
echo "
 ================================================================================
 Account Name         Min Value        Date           Max Value        Date
 ================================================================================" > ${out_fl}_accMinMax
awk '{if (NR>=4) {printf("%s ", $1)} }' $SCCTMP/out_fl_list | read fl_list
for Fname in $fl_list
do

echo $Fname  `awk '{if (NR>=7) {print $2"\t\t",$1} }' $Fname | sort -n | head -1` `awk '{if (NR>=7) {print $2"\t\t",$1} }' $Fname | sort -n | tail -1`|  
awk 'FS="_acc"{print $2}' |  awk '{printf("%s\t%8.2f\t%s\t%6.2f\t%s\n",$1,$2,$3,$4,$5)}' >> ${out_fl}_accMinMax
done 	# while read Fname
  cat ${out_fl}_accMinMax
 _PRT ${out_fl}_accMinMax
 ;; 
 

2d)

awk '{if (NR>=4) {printf("%s ", $1)} }' $SCCTMP/out_fl_list | read fl_list
print -n "" > ${out_fl}_dailyMinMax
for Fname in $fl_list
do
echo working with $Fname
echo "" >> ${out_fl}_dailyMinMax
echo $Fname |sed 's-/aedc/tmp/scc/aedc/AccFileData_acc--' >>  ${out_fl}_dailyMinMax
echo "==============================================
Day		|  Max  time	| Min   time
==============================================" >> ${out_fl}_dailyMinMax
grep "^20" $Fname|awk 'FS=":"{print $1}'|sort -u > $SCCTMP/days
	while read day
	do
	echo working with $day
        grep "^$day" $Fname |sort -n -k2 |sed "s-${day}:--" |
	    awk 'OFS="\t"{print $2,$1}'> $SCCTMP/day_val
	head -1 $SCCTMP/day_val | read min
	tail -1 $SCCTMP/day_val | read max
        echo "$day	| $max	| $min" >> ${out_fl}_dailyMinMax
	done < $SCCTMP/days	# while read day
done 	# while read Fname
 cat ${out_fl}_dailyMinMax
_PRT ${out_fl}_dailyMinMax


 ;;
  3)
 read hrs?"enter your favorit hr(s) [default 21]>> "
     if [ -z "$hrs" ]
     then
     hrs=21
     fi

  print -n "" > ${base_out_fl}_SpecificHr

     read mtrx_ch?"  What is your favorit viue ?
	1) tabular
	2) matrix  ( day vs. hr ; 1Paragraph/acc )
	3) matrix  ( acc vs. hr ; 1Sheet/day )
  Your choice is [default 1] >> "
     if [ -z "$mtrx_ch" ]
     then
     mtrx_ch=1
     fi
       case $mtrx_ch in
       1) echo not applayed yet ;;
       2) echo "     date	`echo $hrs | sed 's/ /	/g'`
yyyy/mm/dd
================`echo $hrs | sed 's/[0-9]//g' |sed 's/^/========/;s/ /========/g'`" >> ${base_out_fl}_SpecificHr
  grep "$base_out_fl" $SCCTMP/out_fl_list |
       while read ln
       do
       echo $ln | awk 'OFS="\n"{print $1,$2}' | { read out_fl ; read acc ; }
       echo "\n${acc}\n---------------" >> ${base_out_fl}_SpecificHr
       rm -f ${out_fl}_sub_specific_*
     print -n "" > ${out_fl}_sub_specific
     for hr in $hrs
     do
     sed "s@^@$hr @" $out_fl | awk 'NR>=7{if (substr($2,12,2)==$1){print $0}}' | sed "s@^$hr @@" >> ${out_fl}_sub_specific
     done
       awk 'FS=":"{print $1}' ${out_fl}_sub_specific | sort -u | while read day
       do
       echo $day >> ${out_fl}_sub_specific_day
       for hr in $hrs
       do
       grep "${day}:${hr}" ${out_fl}_sub_specific | awk '{print $2}' | read val
       if [ -z "$val" ]
       then
       val="---"
       fi
       echo $val >> ${out_fl}_sub_specific_h${hr}
       done
       done
       paste ${out_fl}_sub_specific_* > ${out_fl}_sub_specific1
       sort ${out_fl}_sub_specific1 > ${out_fl}_specific
       cat ${out_fl}_specific >> ${base_out_fl}_SpecificHr

       done 		# while read ln  from  $SCCTMP/out_fl_list

     cat ${base_out_fl}_SpecificHr
     _PRT ${base_out_fl}_SpecificHr
       ;;
       
       3) echo not applayed yet 
       print -n "" > $SCCTMP/out_sheet
       grep "^20" `grep "${SCCTMP}/${base_out_fl}" $SCCTMP/out_fl_list|head -1| awk '{print $1}'`|
           cut -c 1-10 | sort -u | while read day
	   do
	   echo "working with $day ..."
	   echo " Amps for  ${day} 
acc             `echo $hrs | sed 's/ /	/g'`
================`echo $hrs | sed 's/[0-9]//g' |sed 's/^/========/;s/ /========/g'`
" >> $SCCTMP/out_sheet
	   echo "\n${day}\n-----------" >> $SCCTMP/out_sheet
	   grep "${SCCTMP}/${base_out_fl}" $SCCTMP/out_fl_list | while read ln
	       do	   
	       echo $ln | awk 'OFS="\n"{print $1,$2}' | { read out_fl ; read acc ; }
	       grep DATA $out_fl | sed 's/P:/@/;s/\./@/;s/ CTS//' | awk 'FS="@"{print $2,$4}'|
	            awk '{printf("%-20s:   ", $0)}'
	       for hr in $hrs
	          do
	          grep "${day}" $out_fl  | grep ":${hr}:" | awk '{printf("%s\n", $2)}' |read val
	          if [ -z "${val}" ] ; then
	          val="--"
	          fi
	          echo $val | awk '{printf("%6s ", $1)}'
	          done		# for hr in $hrs
	       echo
	       done >> $SCCTMP/out_sheet		# while read ln
#	       cat $SCCTMP/sub_out_sheet >> $SCCTMP/out_sheet
#	   awk '{print $1}' $SCCTMP/sub_out_sheet | sed "s/N$//" | sort -u | while read grp
#	      do
#	      echo "\n${grp}\n-----------------" >> $SCCTMP/out_sheet
#	      grep "$grp" $SCCTMP/sub_out_sheet | sed "s/${grp} //"| sort >> $SCCTMP/out_sheet
#	      done				# while read grp	
#	   echo "\f" >> $SCCTMP/out_sheet
	   done		# while read day
	   cat $SCCTMP/out_sheet
	   _PRT $SCCTMP/out_sheet
#	   dcc_ss_replace -a $SCCTMP/out_sheet
       ;;

     esac		# case $mtrx_ch in
  ;;
  *) break
  ;;
 
esac
 
done	 # main loop of process_alldata
fi
}



function process_data {
if [ "$acc_prsnt_flag" = "true" ]
then
#more $out_fl
  while true
  do
# data operation menu
# -------------------
echo "
  What do you want to do with this data ?
	1 ) View all data
	..) Get peak value per day
		2a) Get max value per day
		2b) Get min value per day
		2c) Get both max&min values per day
	3 ) Filter on specific hr(s)
        4 ) Return


"
read ch?"  Your choice is <CR> to Exit >> "
echo your choice now is $ch
  case $ch in
  1) more $out_fl
     _PRT $out_fl
  ;;

  2a) head -6 $out_fl | sed 's/DATA/Daily Max DATA/' | sed '/date/s/value  /max_val/' > ${out_fl}_daymax
     print -n "" > ${out_fl}_sub_daymax
     awk 'NR>6,FS=":"{print $1}' $out_fl | sort -u | while read dd
      do
      grep $dd $out_fl |grep -v  between | sort  -n -k2 | tail -1 >> ${out_fl}_sub_daymax
      done
     cat ${out_fl}_sub_daymax >> ${out_fl}_daymax
     head -3 $out_fl | tail -1 >> ${out_fl}_daymax
     sort -n -k2 ${out_fl}_sub_daymax | tail -1 >> ${out_fl}_daymax
     cat ${out_fl}_daymax
     _PRT ${out_fl}_daymax
  ;;

  2b) head -6 $out_fl | sed 's/DATA/Daily Max DATA/' | sed '/date/s/value  /min_val/' > ${out_fl}_daymin
     print -n "" > ${out_fl}_sub_daymin
     awk 'NR>6,FS=":"{print $1}' $out_fl | sort -u | while read dd
      do
      grep $dd $out_fl |grep -v  between | sort  -n -k2 | head -1 >> ${out_fl}_sub_daymin
      done
     cat ${out_fl}_sub_daymin >> ${out_fl}_daymin
     head -3 $out_fl | tail -1 >> ${out_fl}_daymin
     sort -n -k2 ${out_fl}_sub_daymin | head -1 >> ${out_fl}_daymin
     cat ${out_fl}_daymin
     _PRT ${out_fl}_daymin
  ;;

  2c) 
      #head -7 $out_fl | sed 's/DATA/Daily Peak DATA/' | sed '/date/s/value  /max_val/;s/   status/min_val/' > ${out_fl}_daypk
      head -3 $out_fl | sed 's/DATA/Daily Peak DATA/' > ${out_fl}_daypk
      echo "      date      max_val  	min_val" >> ${out_fl}_daypk
      head -6 $out_fl | tail -2 | awk '{print $1}' >> ${out_fl}_daypk
      print -n "" > ${out_fl}_sub_daypk
      awk 'NR>6,FS=":"{print $1}' $out_fl | sort -u | while read dd
      do
      print -n "`grep $dd $out_fl |grep -v  between | sort  -n -k2 | tail -1 | awk '{print $1,$2}' |sed 's/:/	/'`"  >> ${out_fl}_sub_daypk
      grep $dd $out_fl |grep -v  between | sort  -n -k2 | head -1 | sed 's/:/ /' | awk '{print "\t" $2,$3}' >> ${out_fl}_sub_daypk
      done
     cat ${out_fl}_sub_daypk >> ${out_fl}_daypk
     head -3 $out_fl | tail -1 >> ${out_fl}_daypk
     sort -n -k3 ${out_fl}_sub_daypk | tail -1 | awk '{print $1"\t"$2,$3}' >> ${out_fl}_daypk
     sort -n -k5 ${out_fl}_sub_daypk | head -1 | awk '{print $1 "\t\t\t" $4,$5}' >> ${out_fl}_daypk
     cat ${out_fl}_daypk
     _PRT ${out_fl}_daypk


  ;;

  3) read hrs?"enter your favorit hr(s) [default 21]>> "
     if [ -z "$hrs" ]
     then
     hrs=21
     fi
     print -n "" > ${out_fl}_sub_specific
     for hr in $hrs
     do
     sed "s/^/$hr /" $out_fl | awk 'NR>7{if (substr($2,12,2)==$1){print $0}}' | sed "s/^$hr //" >> ${out_fl}_sub_specific
     done
    
     read mtrx_ch?"  What is your favorit viue ?
	1) tabular
	2) matrix
  Your choice is [default 1] >> "
     if [ -z "$mtrx_ch" ]
     then
     mtrx_ch=1
     fi
       case $mtrx_ch in
       1)
       head -6 $out_fl | sed "s/DATA/DATA at $hrs/" > ${out_fl}_specific
       sort ${out_fl}_sub_specific >> ${out_fl}_specific
       cat ${out_fl}_specific
       _PRT ${out_fl}_specific
       ;;
       2)
       head -3 $out_fl | sed "s/DATA/DATA at $hrs/" > ${out_fl}_specific
       echo "     date	`echo $hrs | sed 's/ /	/g'`
yyyy/mm/dd
================`echo $hrs | sed 's/[0-9]//g' |sed 's/^/========/;s/ /========/g'`" >> ${out_fl}_specific
       rm -f ${out_fl}_sub_specific_*
       awk 'FS=":"{print $1}' ${out_fl}_sub_specific | sort -u | while read day
       do
       echo $day >> ${out_fl}_sub_specific_day
       for hr in $hrs
       do
       grep "${day}:${hr}" ${out_fl}_sub_specific | awk '{print $2}' | read val
       if [ -z "$val" ]
       then
       val="---"
       fi
       echo $val >> ${out_fl}_sub_specific_h${hr}
       done
       done
       paste ${out_fl}_sub_specific_* > ${out_fl}_sub_specific1
       sort ${out_fl}_sub_specific1 >> ${out_fl}_specific
       cat ${out_fl}_specific
       _PRT ${out_fl}_specific
       ;;
       esac
  ;;

  *) break
  ;;

  esac
  done
fi
}



#===================
#  START POINT
#===================


out_fl=$SCCTMP/AccFileData
UsrIntrMod=true			 # user interface mode flag :false in case of -acc,-f options
					# 			   : true otherwise

case $1 in
-acc)			# case $1 in
UsrIntrMod=false
echo $2 | sed 's/@/</' | read name
enter_range
data_src=2
#data_src_select
get_data
process_data
;;

*)			# case $1 in
while true 
do
InFl="$SCCTMP/acc_list"
echo "`tput bold`write here :
   ==> a list of accounts to be reported	; <CR> terminates the list 
For Outgoing ( <HAVG )  For Incoming ( <HMAX )  For Instantaneous each 15 min ( <INST OR <15MIN )
   ==> -f <input_file_name>		; Contains ACC List`tput sgr0`"
while read inpt
do
   case `echo V$inpt | awk '{print $1}'` in
   V)   break ;;
   V-f) InFl=`echo $inpt | sed 's/-f //'`
        break ;;
   *)   echo "$inpt" ;;
   esac
done  > $InFl	# while read inpt

in_file_mode
read cont?"continue other search? ([y]/n) >> "
if [ -z "$cont" ]
then
cont=y
fi
   case $cont in
   n|N|no|No|NO)
   break
   esac
done
;;
esac			# case $1 in
