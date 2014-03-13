#!/bin/sh

echo "User Stock Status Action Buydate Dummy Selldate dummy Buyprice Sellprice Gain%" |awk '{printf "%-15s %-5s %-10s %-7s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$7,$9,$10,$11}'
curl "http://www.thelion.com/bin/port.cgi" |egrep -o "user_id=[A-Za-z0-9.-_]+" |cut -d'>' -f1 |sort |uniq |while read topuser
do
    export username=`echo $topuser |cut -d'=' -f2`
    curl "http://www.thelion.com/bin/port.cgi?$topuser" |egrep "?sf=[A-Z]+" |grep -v Comment |sed "s/<tr class=z[0-9]><td ><a href=\/bin\/forum\.cgi?sf=//g" |sed 's/<\/td><td>/ /g' |sed 's/[0-9][0-9]:[0-9][0-9]//g' |sed 's/<font class=t_u>//g' |sed 's/<font class=t_d>//g'|sed 's/<\/a>//g' |cut -d'>' -f4- |cut -d'<' -f1 |while read trans
    do
	echo $username $trans |awk '{printf "%-15s %-5s %-10s %-7s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}'
    done
done
