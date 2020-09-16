#!/bin/bash

>tmp

export MARKETWATCH=marketwatchgames.csv #Top 10 players' pick
cat $MARKETWATCH |grep ',Buy,' |awk -F',' '{if( $4<10 ){print $0} }' |cut -d',' -f1 |sort  >> tmp

export FOOLPICKS=foolrecentpick.csv #high rating (>60%) players' pick
cat $FOOLPICKS |awk -F',' '{if( $4>60.0 ){print $1} }' |sort  >> tmp

cat seekingalphalong.csv |sort >> tmp

cat gurufocus.csv >> tmp

cat whalewisdom*.csv |cut -d',' -f1 |sort |uniq >> tmp

cat tmp |sort |uniq -c |sort -r -n | egrep -v '\s+1|\s+2'  |while read line
do #picked by more than 3+   
  ticker=$(echo $line |awk '{print $2}')
  cap=$(curl -s  https://www.tipranks.com/api/stocks/getData/?name=$ticker |jq .marketCap | awk '{if ($1>1000000000) {print $1}}')
  [[ ! -z $cap ]] && echo $line #only filter out MarketCap>1B  
done
