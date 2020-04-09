#!/bin/bash

>tmp

export MARKETWATCH=marketwatchgames.csv #Top 10 players' pick
cat $MARKETWATCH |grep ',Buy,' |awk -F',' '{if( $4<10 ){print $0} }' |cut -d',' -f1 |sort  >> tmp

export FOOLPICKS=foolrecentpick.csv #high rating (>75%) players' pick
cat $FOOLPICKS |awk -F',' '{if( $4>75.0 ){print $1} }' |sort  >> tmp

cat seekingalphalong.csv |sort >> tmp

cat tmp |sort |uniq -c |sort -r -n | awk '{if( $1>2 ){print $0} }' #in-common stocks for 3+ top players
