#!/bin/ksh
##################################################################
# purpose :to insert data to iutddb..TSCC6_Alex_load_Ratio 
# 		for Distribution load  to alex. city load
#Last modification : 3 aug. 2004 
##################################################################


INSERT_T () {
cp /dev/null /tmp/scc/rows
{
while read ln 
do
echo $ln|awk '{print $1}'|read day
echo $ln|awk '{print $2}'|read d_t
echo $ln|awk '{print $3}'|read hr
echo $ln|awk '{print $4}'|read mw_a
echo $ln|awk '{print $5}'|read mw_t
echo $ln|awk '{print $6}'|read rt
echo $ln|awk '{print substr($1,9,2)}'|read dd
echo $ln|awk '{print substr($1,6,2)}'|read mm
echo $ln|awk '{print substr($1,1,4)}'|read yy

echo '$day' ,$d_t ,$hr,$mw_a,$mw_t,$rt,$dd, $mm ,$yy
echo "
use iutddb 
go
insert into TSCC6_Alex_load_Ratio values ('$day' ,$d_t ,$hr,$mw_a,$mw_t,$rt, $dd, $mm , $yy)
go"|isql -Usa -Ptejedor
done
}<  $INFILE  >/tmp/scc/rows
grep "1 row" /tmp/scc/rows |wc -l |awk '{print $1}' |read acc 
echo   $acc rows inserted to iutddb..TSCC6_Alex_load_Ratio table
}


cp /dev/null  /tmp/scc/rows
cp /dev/null  /tmp/scc/alex_load_ratio
mktime `date +"%Y/%m/%d:00:00:00"`|awk '{ print $1-86400}'|read yesterday
var_asctime $yesterday "%Y/%m/%d"|read sugg_day
read day?"Enter Day for report in for $sugg_day : "

if [[ -z  ${day} ]]
then
day=$sugg_day
fi
#echo $day| awk '{printf("

hours="02 04 06 08 10 12 14 16 18 19 20 21 22 24"
for hr in $hours
do
read City_v?"Enter City MW < ${hr} > : "
	if [[ -z   $City_v ]]
	then
	echo " Sorry Data for  hr   $hr   is missed . Try again !" 
	exit
	fi
mktime  ${day}:${hr}:00:00 |read asc_t
echo "
use aedcdb
go
select  '$day' , '$asc_t', '$hr',  str(C0434_value,6,1) ,  $City_v ,  str(C0434_value/${City_v}*100,5,1) , 
'$dd', '$mm', '$yy'  from T0434_peak_data   where  C0401_aid=8537 and C0434_date=$asc_t
go"|isql -Udbu -Pdbudbu|grep "${day}" |read data

if [[  -z  "${data}" ]]
then 
echo ${data}    sorry data not found
echo "select  '$day', '$asc_t', '$hr', 'NULL' , $City_v ,
 'NULL' , '$dd', '$mm', '$yy'  
go"|isql -Udbu -Pdbudbu|grep "${day}" >> /tmp/scc/alex_load_ratio
else
echo "${data}" >> /tmp/scc/alex_load_ratio
fi
done
 

cat /tmp/scc/alex_load_ratio
read op?"Do You Want to Change Data < y /[n] > " 
if [ "$op" = y  ]
then
xedit /tmp/scc/alex_load_ratio

fi 

echo " Inserting Data "

INFILE=/tmp/scc/alex_load_ratio
INSERT_T  

rm  -f    /tmp/scc/alex_load_ratio
