#!/bin/bash

>tmpgames
for index in 0 10 20 30
do
    curl "http://www.marketwatch.com/game/find?index=$index&sort=NumberOfPlayers&descending=True"  |egrep -o '/game/.+'  |grep title  |cut -d '"' -f1 | cut -d'/' -f3 >> tmpgames
done
#curl "http://www.marketwatch.com/game/find?sort=NumberOfPlayers&descending=True"  |egrep -o '/game/.+'  |grep title  |cut -d '"' -f1 | cut -d'/' -f3 |while read game
cat tmpgames |while read game
do #marketwatch.com stock trading games with most players
	echo "Player Rank Stock Date Action Shares Price" |awk '{printf"%-30s %-5s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$6,$7}' > marketwatch-$game.log
	for page in 0 10 20 
	do #Top 100 players
		rank=$page
		curl "http://www.marketwatch.com/game/$game/ranking?index=$page" |egrep "/game/$game/portfolio/holdings" |cut -d'>' -f2 |cut -d'"' -f2 |cut -d'=' -f2- |sed -e 's/amp//g' -e 's/;//g' |while read url
		do	#Transactions	
			name=`echo $url|cut -d'&' -f1 |cut -c1-29`
			rank=`expr $rank + 1`		
			curl "http://www.marketwatch.com/game/$game/portfolio/transactionhistory?name=$url" |egrep -A 12 "/investing/stock/" |grep -v numeric  |sed -e 's/<td>//g'  -e 's/<\/td>//g'  -e 's/<a href="\/investing\/stock\///g' -e 's/<\/a>//g' -e 's/^[ \t]*//g'  -e '/^$/d' |cut -d'"' -f1 |dos2unix |tr '\n' ' ' |sed -e 's/\-\-/\n/g' |sed "s/<span title='InsufficientBuyingPower'>(Canceled)<\/span>//g" |awk '{print $0}' |while read trans
			do			
				echo $name $rank $trans |egrep -v '<span>' |sed 's/\%20/-/g' |awk '{printf"%-30s %-5s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$8,$9,$10}' >> marketwatch-$game.log
			done			
		done	
	done
done

