#!/bin/sh

export daysago=0
if [ $1 ]; then
    export daysago=$1
fi 
thedate=`date -d "$daysago day ago" +%Y-%m-%d`

echo "Player Rank Stock Date Time Price" |awk '{printf "%-20s%-5s%-10s%-15s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7}'
cat fooltopplayers |while read player
do
	rank=`curl "http://api.fool.com/caps/ws/caps/ws/Player/$player/Picks/Active?apikey=$FOOL_API_KEY" |grep PlayerRank |cut -d'>' -f2 |cut -d'<' -f1`
	curl "http://api.fool.com/caps/ws/caps/ws/Player/$player/Picks/Active?apikey=$FOOL_API_KEY" |egrep -A 2 -B 5 "<StartDate>$thedate"  |egrep "TickerSymbol|StartDate|StartPrice|--" | cut -d'>' -f2 |cut -d'<' -f1 |tr '\n' ' ' |sed "s/--/\n/g" |while read  trans
	do
		echo $player $rank $trans |awk '{printf "%-20s%-5s%-10s%-15s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7}'
	done
done
