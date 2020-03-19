#!/bin/bash

>marketwatchgames.csv
for game in lifetime-stock-market-game invest-until-you-die invest-until-you-die-two-2 official-reddit-challenge-2020 trades-for-life eths20192020
do
    for page in 0 10 20 30 40 50 
    do
	curl -stderr -L "https://www.marketwatch.com/game/$game/rankings?partial=true&index=$page" |egrep -o "/game/$game/portfolio\?p=[0-9]+.+ class" |cut -d'"' -f1 |while read portfolio
	do
 	    name=$(echo $portfolio |egrep -o 'name=\S+' |cut -d'=' -f2 |sed 's/%20/ /g')
	    curl -stderr "https://www.marketwatch.com/"$portfolio > tmp
	    rank=$(cat tmp|egrep 'rank__number ">'  |cut -d'>' -f2 |cut -d'<' -f1)
	    cat tmp  |egrep -A 9 '</mini-quote>' |egrep -o '[A-Z0-9]+<\/mini-quote>|class="primary">[0-9]+%|class="text">[A-Za-z]+' |cut -d'<' -f1 |cut -d'>' -f2 |tr  '\n' ',' |sed -e 's/Buy/Buy\n/g' -e 's/Short/Short\n/g' |sed 's/^,//g' |while read holding
		do
		    echo $holding,$rank,$portfolio >> marketwatchgames.csv
		done
	done
    done
done
