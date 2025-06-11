#!/bin/ksh
#---------------------------------------------------------------------------
# TITLE         : Daily max Amp for CT point
# PURPOSE       : to Determind Daily Max Load report for certen CT point from HAVG account
# GROUP         : IS
# AUTHOR        : Alaa Nagy , Mamdouh Soliman
# DATE          : 13 October 2004
#------------------------------------------------------------------------------
. /aedc/etc/work/aedc/SCC/aedc_SCC_functions
#offset="Jan  1 1970 02:00AM"
#offset="Jan  1 1970 03:00AM"
while true
do
read point_name1?"
Enter POINT NAME in form P:group_name.point_name >>> "
if  [[ -z $point_name1 ]]
then
exit
fi
 
echo $point_name1|awk 'FS="P:" {print $2}'|read point_name
echo ${point_name}
echo "
select str(C0401_aid,8,0)+'@'+C0401_description from T0401_accounts where C0401_name  like '${point_name}<15MIN' 
go"|isql -Udbu -Pdbudbu| { read ; read ; read ln ; }

echo $ln |awk 'FS="@" {print $1}'|read id
echo $ln |awk 'FS="@" {print $2}'|sed 's/INST_VOLTAGE FOR//'|sed 's/kV//' |read desc
	if [[ -z $id ]]
	then
echo $id
echo " 
 Sorry no Data for this Point "
	else
echo " 
Volt for Cell $point_name ( Cell :  $desc )
_____________________________________________________________"
echo "
set nocount on
go
select '   Day'=convert(char(10),dateadd(second,C0432_date,'${offset}'),111)+':'+
                substring(convert(char(8),dateadd(second,C0432_date,'${offset}'),108),1,2) , 
'Max_'= str(max(C0432_value_r),5,1) from T0432_data  
where C0401_aid=${id}
group by convert(char(10),dateadd(second,C0432_date,'${offset}'),111)+':'+
substring(convert(char(8),dateadd(second,C0432_date,'${offset}'),108),1,2)
go"|isql -Udbu -Pdbudbu
	fi

read mody?" <CR> to continue OR <q> to quit : "
if [ "$mody" = "q" ]
then 
break
fi
done
