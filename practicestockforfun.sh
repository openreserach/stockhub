#!/bin/sh

for page in 0 10 20 30 40 50 60 70 80 90 
do
	curl "http://www.marketwatch.com/game/practice-stocks-for-fun/ranking?index=$page" |egrep "/game/practice-stocks-for-fun/portfolio/holdings" |cut -d'>' -f2 |cut -d'"' -f2 |cut -d'=' -f2- |sed -e 's/amp//g' -e 's/;//g' |while read url
	do
		#curl "http://www.marketwatch.com/game/practice-stocks-for-fun/portfolio/holdings?name="$url
		curl "http://www.marketwatch.com/game/practice-stocks-for-fun/portfolio/transactionhistory?name="$url 
		echo "http://www.marketwatch.com/game/practice-stocks-for-fun/portfolio/transactionhistory?name="$url 
		#echo "http://www.marketwatch.com/game/practice-stocks-for-fun/portfolio/holdings?name="$url
		exit
	done
	exit
done

