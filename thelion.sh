#!/bin/sh

echo "user stock status action buydate dummy selldate dummy buyprice sellprice gain" |awk '{printf "%-15s %-5s %-10s %-7s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$7,$9,$10,$11}'
curl "http://www.thelion.com/bin/port.cgi" |egrep -o "user_id=[A-Za-z0-9.-_]+" |sort |uniq |while read topuser
do
    export username=`echo $topuser |cut -d'=' -f2`
    curl "http://www.thelion.com/bin/port.cgi?$topuser" |egrep "?sf=[A-Z]+" |grep -v Comment |sed "s/<tr class=z[0-9]><td><a href=\/bin\/forum\.cgi?sf=//g" | sed "s/<tr class=z><td><a href=\/bin\/forum\.cgi?sf=//g"  |sed 's/<\/a><\/td><td>/ /g' |sed 's/<\/td><td>/ /g' |sed 's/<font class=t_u>//' |cut -d'<' -f1 |cut -d'>' -f2 |while read trans
    do
        echo $username $trans |awk '{printf "%-15s %-5s %-10s %-7s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$7,$9,$10,$11}'
    done
done
