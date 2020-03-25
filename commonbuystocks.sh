#!/bin/bash

>tmp

export MARKETWATCH=marketwatchgames.csv #Top 10 players' pick
cat $MARKETWATCH |awk -F',' '{if( $4<10 ){print $0} }' |cut -d',' -f1 |sort  >> tmp

export FOOLPICKS=foolrecentpick.csv #highest rating players' pick
cat $FOOLPICKS |grep ',5,' |cut -d',' -f1 |sort  >> tmp

cat seekingalphalong.csv |sort >> tmp

cat tmp |sort |uniq -c |sort -r -n |head -n 20
