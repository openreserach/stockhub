#!/bin/bash


export UrlHighestRatedNewPlayers="http://caps.fool.com/Ajax/GetStatsPageData.aspx?statsmajor=PlayerStats&statsminor=HRNP&ViewMode=Detailed"

\rm cookie
curl -c cookie -b cookie $UrlHighestRatedNewPlayers >tmp$$ 
export Lines=`cat tmp$$ |wc -l`
while [[ $Lines -lt 100 ]]; do #do until page containing data generated
     curl -c cookie -b cookie $UrlHighestRatedNewPlayers > tmp$$	
     export Lines=`cat tmp$$ |wc -l`
done
cat tmp$$ |egrep  -o '/player/\w+.aspx' |cut -d'/' -f3 |cut -d'.' -f1 > fooltopnewplayers


export daysago=0
if [ $1 ]; then
    export daysago=$1
fi 
thedate=`date -d "$daysago day ago" +%Y-%m-%d`

echo "Player Rank Stock Date Time Price" |awk '{printf "%-20s%-10s%-10s%-15s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7}'
cat fooltopnewplayers |while read player
do
	rank=`curl "http://www.fool.com/a/caps/ws/caps/ws/Player/$player/Picks/Active?apikey=$FOOL_API_KEY" |grep PlayerRank |cut -d'>' -f2 |cut -d'<' -f1`
	curl "http://www.fool.com/a/caps/ws/caps/ws/Player/$player/Picks/Active?apikey=$FOOL_API_KEY" |egrep -A 2 -B 5 "<StartDate>$thedate"  |egrep "TickerSymbol|StartDate|StartPrice|--" | cut -d'>' -f2 |cut -d'<' -f1 |tr '\n' ' ' |sed "s/--/\n/g" |while read  trans
	do
		echo $player $rank $trans |awk '{printf "%-20s%-10s%-10s%-15s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7}'
	done
done

\rm tmp$$ 
