#!/bin/ksh
#---------------------------------------------------------------------------
# TITLE         : Daily max Amp for CT point
# PURPOSE       : to Determind Daily Max Load report for CT point from HAVG account
# GROUP         : IS
# DATE          : 20 Mar 2006
#------------------------------------------------------------------------------
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions


#offset="Jan  1 1970 02:00AM"
#offset="Jan  1 1970 03:00AM"

op_fl=$SCCTMP/tmp_max_amp
rm -f $SCCTMP/tmp_max_amp*
cnt=1

while true
do
print -n "" > ${op_fl}err
echo "\n\nMax Load for the following CTA_list:\n" > ${op_fl}lst
print -n "" > $SCCTMP/point_list
echo "
 <<<< Max CTA_points = 7 >>>>>"

while read point_name1?" Enter CT name [P:]group_name.point_name 
<CR> end entry list (${cnt}) : " 
do
if [[ -z $point_name1 || ${cnt} -eq 7 ]]
 then
 break
 cnt=1
 else
 echo "${point_name1}" >> $SCCTMP/point_list
 echo ${cnt}|awk '{print $1+1}'|read cnt
fi
done

fl_lst=""
n=1
while read point_name1
do
echo $point_name1|sed 's/P://' | sed 's/CTK/CTA/'|read point_name
echo "
if exists (select * from T0401_accounts where C0401_name  like '%${point_name}<HAVG'
or C0401_name  like '%${point_name}<HMAX' )
select str(C0401_aid,8,0)+'@'+C0401_description from T0401_accounts where C0401_name  like '%${point_name}<HAVG' or 
C0401_name  like '%${point_name}<HMAX'
else
print '\n\nno point'    
go"|isql -Udbu -Pdbudbu| { read ; read ; read ln ; }
        if [[ "$ln" = "no point" ]]
        then
echo "  Sorry No Data was found $point_name" | tee -a ${op_fl}err
 nn=$n
	else
 nn=`expr $n + 1`
echo $ln |awk 'FS="@" {print $1}'|read id
echo $ln |awk 'FS="@" {print $2}'|sed 's/CT//'|sed 's/AMPS//'|sed 's/AMP//' |read desc
echo " $n ) $point_name (  $desc )" | tee -a ${op_fl}lst
echo "
set nocount on
go
select '   Day'=convert(char(10),dateadd(second,C0432_date,'${offset}'),111) ,'|', 'Max_Amp'= str(max(C0432_value_r),5,1) from T0432_data  
where C0401_aid=${id}
group by convert(char(10),dateadd(second,C0432_date,'${offset}'),111)
select '   Day'=convert(char(10),dateadd(second,C0434_date,'$offset'),111) ,'|', 'Max_Amp'= str(max(C0434_value),5,1) from   T0434_peak_data
where C0401_aid=${id} 
group by convert(char(10),dateadd(second,C0434_date,'$offset'),111)
go"|isql -Udbu -Pdbudbu  |grep "[0-9]"|awk 'BEGIN {max == 0 ;
 printf("\n%s\t |\t %s\n__________       |       _____\n" , "Day......." ,"Amps ") }; 
{if ( max > $3 ) { max = max } else { max = $3 ; day = $1 } 
{print $1, "\t" ,$2, "\t" , $3}} ;
END { print "__________       |       _____\nmax.......       |      ", max}' | sed "s/Amps/Amps(${n})/" > ${op_fl}$n
fl_lst="$fl_lst ${op_fl}$n"
	fi
n=$nn
done < $SCCTMP/point_list
cat ${op_fl}err > $op_fl
sed 's/\.CT/ .CT/' ${op_fl}lst > ${op_fl}lst1
dcc_ss_replace -i ${op_fl}lst1 > ${op_fl}lst
cat ${op_fl}lst >> $op_fl
echo >> $op_fl
paste $fl_lst | awk 'OFS="\t"{print $1,$2,$3,$6,$9,$12,$15,$18,$21}' | head -3 >> ${op_fl}
 awk 'FS="|"{print $1}' $fl_lst|grep "[0-9]" |sort -u | while read dt
 do
 val=""
 for fl in $fl_lst
 do
 if [ -z "`grep $dt $fl`" ]
 then
 val="$val\t----"
 else
 val="$val\t`grep $dt $fl|awk '{print $3}'`"
 fi
 done
 echo "$dt\t|$val"  >> $op_fl
 done
echo
cat $op_fl
_PRT $op_fl
echo

read mody?" <CR> to continue OR <q> to quit : "
if [ "$mody" = "q" ]
then 
break
fi
done
