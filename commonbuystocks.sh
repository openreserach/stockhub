#!/bin/bash

>tmp

export MARKETWATCH=marketwatchgames.csv #Top 10 players' pick
cat $MARKETWATCH |grep ',Buy,' |awk -F',' '{if( $4<10 ){print $0} }' |cut -d',' -f1 |sort  >> tmp

export FOOLPICKS=foolrecentpick.csv #high rating (>75%) players' pick
cat $FOOLPICKS |awk -F',' '{if( $4>75.0 ){print $1} }' |sort  >> tmp

cat seekingalphalong.csv |sort >> tmp

cat tmp |sort |uniq -c |sort -r -n | awk '{if( $1>1 ){print $0} }' #|while read line
#do
  #ticker=$(echo $line |awk '{print $2}')
  #cap=$(curl -stderr --http2 https://finviz.com/quote.ashx?t=$ticker  |egrep "Market Cap" |egrep -o "[0-9.]+B") #>1.0B cap size
  #[[ ! -z $cap ]] && echo $line
#done
