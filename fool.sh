#!/bin/bash
echo "Player Rating Date Ticker Price" |awk '{printf "%-20s%-10s%-10s%-15s%-10s\n",$1,$2,$3,$4,$5}' > fool.log
export UrlHighestRatedNewPlayers="http://caps.fool.com/Ajax/GetStatsPageData.aspx?statsmajor=PlayerStats&statsminor=HRNP&ViewMode=Detailed"
curl $UrlHighestRatedNewPlayers |egrep -o "\s\s+\w+</a>"  |sed -e 's/\s//g' -e 's/<\/a>//g' |tr 'A-Z' 'a-z' |while read player
do
    rating=`curl http://caps.fool.com/player/$player.aspx |egrep -o 'RatingFormula_lblRating">[0-9]+.[0-9]+<' |egrep -o '[0-9]+.[0-9]+'`
    curl http://caps.fool.com/player/$player.aspx |egrep -A 1000 'class="picksDataView"'  |egrep  "/Ticker/[A-Z]+" |cut -d'>' -f3- |cut -d'<' -f1 |cat -n > tmp1
    curl http://caps.fool.com/player/$player.aspx  |egrep -o 'StartDate">[0-9]+/[0-9]+/[0-9]+' |sed 's/StartDate">//g'  |cat -n > tmp2
    curl http://caps.fool.com/player/$player.aspx  |egrep  '\s+\$[0-9]+.[0-9]+' |sed 's/\s//g' |cat -n > tmp3
    join tmp1 tmp2 |join tmp3 - | while read line
    do
  	echo $player $rating $line |awk '{printf "%-20s%-10s%-10s%-15s%-10s\n",$1,$2,$6,$5,$4}' >> fool.log
    done
done

