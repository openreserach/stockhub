#!/bin/bash

for game in "practice-stocks-for-fun" "redditchallenge2014" "%E5%A4%A7%E5%8D%83%E5%8D%8A%E5%B9%B4%E6%A8%A1%E6%8B%9F%E8%B5%9B" "%E5%A4%A7%E5%8D%83%E5%8D%8A%E5%B9%B4%E7%82%92%E8%82%A1%E6%AF%94%E8%B5%9B"
do #marketwatch.com stock trading games/contest of interest
echo "Player Rank Stock Date Action Shares Price" |awk '{printf"%-30s %-5s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$5,$6,$7}' >$game.log
	for page in 0 10 20 30 40 50 60 70 80 90 
	do #Top 100 players
		rank=$page
		curl "http://www.marketwatch.com/game/$game/ranking?index=$page" |egrep "/game/$game/portfolio/holdings" |cut -d'>' -f2 |cut -d'"' -f2 |cut -d'=' -f2- |sed -e 's/amp//g' -e 's/;//g' |while read url
		do	#Transactions	
			name=`echo $url|cut -d'&' -f1 |cut -c1-29`
			rank=`expr $rank + 1`		
			curl "http://www.marketwatch.com/game/$game/portfolio/transactionhistory?name=$url" |egrep -A 12 "/investing/stock/" |grep -v numeric  |sed -e 's/<td>//g'  -e 's/<\/td>//g'  -e 's/<a href="\/investing\/stock\///g' -e 's/<\/a>//g' -e 's/^[ \t]*//g'  -e '/^$/d' |cut -d'"' -f1 |dos2unix |tr '\n' ' ' |sed -e 's/\-\-/\n/g' |sed "s/<span title='InsufficientBuyingPower'>(Canceled)<\/span>//g" |awk '{print $0}' |while read trans
			do			
				echo $name $rank $trans |sed 's/\%20/-/g' |awk '{printf"%-30s %-5s %-10s %-10s %-10s %-10s %-10s\n",$1,$2,$3,$4,$8,$9,$10}' >> $game.log
			done			
		done	
	done
done

mv "%E5%A4%A7%E5%8D%83%E5%8D%8A%E5%B9%B4%E6%A8%A1%E6%8B%9F%E8%B5%9B.log" 		daqian1.log
mv "%E5%A4%A7%E5%8D%83%E5%8D%8A%E5%B9%B4%E7%82%92%E8%82%A1%E6%AF%94%E8%B5%9B.log"	daqian2.log
