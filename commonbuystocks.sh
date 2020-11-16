#!/bin/bash

>tmp

export MARKETWATCH=marketwatchgames.csv 
cat $MARKETWATCH |egrep ',Buy,' |sort |uniq |while read line
do #recent buy in last 7 days
  transactionDate=$(echo $line |cut -d',' -f2)
  transactionSec=$(date --date "$transactionDate" +'%s')   
  weekagoSec=$(date --date "7 days ago" +'%s')
  [ $transactionSec -gt $weekagoSec ] && echo $line |cut -d',' -f1  >> tmp  
done

export FOOLPICKS=foolrecentpick.csv #high rating (>60%) players' pick
cat $FOOLPICKS |awk -F',' '{if( $4>60.0 ){print $1} }' |sort  >> tmp

cat seekingalphalong.csv |sort >> tmp #recent Long with ~48 hours

cat gurufocus.csv |egrep "Buy:|Add:" |cut -d':' -f2 |tr ',' '\n' >> tmp

cat whalewisdom*.csv |cut -d',' -f1 |sort |uniq >> tmp

cat tmp |sort |uniq -c |sort -r -n | egrep -v '\s+1\s|\s+2\s'  |while read line
do #picked by more than 3+ sources  
  ticker=$(echo $line |awk '{print $2}')
  cap=$(curl -s  https://www.tipranks.com/api/stocks/getData/?name=$ticker |jq .marketCap | awk '{if ($1>1000000000) {print $1}}')
  [[ ! -z $cap ]] && echo $line #only filter out MarketCap>1B  
done
