#!/bin/sh

export daysago=1
if [ $1 ]; then
    export daysago=$1
fi 
thedate=`date -d "$daysago day ago" +%Y-%m-%d`

cat fooltopplayers |while read player
do
	curl "http://api.fool.com/caps/ws/caps/ws/Player/$player/Picks/Active?apikey=$FOOL_API_KEY" |egrep -A 2 -B 5 "<StartDate>$thedate"  |egrep "TickerSymbol|StartDate|StartPrice|--" | cut -d'>' -f2 |cut -d'<' -f1 |tr '\n' ' ' |sed "s/--/\n/g" |while read  trans
	do
		echo $player $trans 
	done
done
