#!/bin/ksh

#SS="INDUSTRIAL BORG"
for SS in "INDUSTRIAL BORG" "NEW BORG" "OLD BORG"
do
#Mnth="2021_01"

for Mnth in 2021_01 2021_02 2021_03 2021_04 2021_05
do
echo "${SS}_${Mnth}" | sed 's/ /_/' | read outFl
echo "	Voltages $SS during $Mnth 
day  Hr	TR1	TR2	TR3	TR4	TR5
==   ==	====================================" > /home/sis/REPORTS/Temporary/Eng_Hany/Volt_BORG/$outFl



cd /home/sis/REPORTS/DAILY_Max_Min_VOLT/${Mnth}
ls *SSVoltHr | while read fl
  do
  echo $fl|cut -c 1,2 |read day
  grep -p "$SS" $fl | grep "|" | awk 'ORS="\t"{print $2}' | read V_at04
  grep -p "$SS" $fl | grep "|" | awk 'ORS="\t"{print $5}' | read V_at12
  grep -p "$SS" $fl | grep "|" | awk 'ORS="\t"{print $8}' | read V_at21

  echo "$day   04	$V_at04
$day   12	$V_at12
$day   21	$V_at21" >> /home/sis/REPORTS/Temporary/Eng_Hany/Volt_BORG/$outFl
  done
done
done
