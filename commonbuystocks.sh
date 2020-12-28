#!/bin/bash

export MARKETWATCH="marketwatchgames.csv"
export FOOLPICKS="foolrecentpick.csv" 
export GAMES_IN_RECENTDAY=30    #days 
export FOOL_PLAYER_RATING=90.0  #percent
export MARKET_CAP=1000000000    #$1B 

>tmp
cat $MARKETWATCH |egrep ',Buy,' |sort |uniq |while read line
do #recent buy in last N days
  transactionDate=$(echo $line |cut -d',' -f2)
  transactionSec=$(date --date "$transactionDate" +'%s')   
  weekagoSec=$(date --date "$GAMES_IN_RECENTDAY days ago" +'%s')  
  [ $transactionSec -gt $weekagoSec ] && echo $line |cut -d',' -f1 #>> tmp  
done |sort |uniq >> tmp

curl -s "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |cut -d',' -f1 |egrep -v '^$' |sort |uniq >> tmp    #Barron's pick
cat $FOOLPICKS        |awk -F',' '{if( $4>'$FOOL_PLAYER_RATING'){print $1}}'|sort >> tmp  #FOOL high rating players' picks
cat seekingalphalong.csv  |sort >> tmp                                                    #recent(~2days) LONG recommendation by seekingalpha
cat gurufocus.csv         |egrep "Buy:|Add:" |cut -d':' -f2 |tr ',' '\n'>>tmp             #Guru's recent Buy/Add
cat whalewisdom*.csv      |cut -d',' -f1 |sort |uniq  >> tmp                              #13F recent filer's holdings
cat ark.csv |egrep '^ARK' |cut -d',' -f2 |sort |uniq |egrep [A-Z]+ >> tmp                 #all ARK* invenstment holdings

echo "Sources Ticker    ETF   Weight"
cat tmp |sort |uniq -c |sort -r -n | egrep -v '\s+1\s|\s+2\s'  |while read line
do #picked ticker>1B cap size, from 3+ sources, and show ETF largest exposure (if available)
  ticker=$(echo $line |awk '{print $2}')
  etf_weight=$(curl -s "https://etfdb.com/stock/$ticker/"|egrep Ticker|egrep Weighting|head -n 1 |egrep -o "href=\"/etf/[A-Z]+/\">[A-Z]+<|Weighting\">[0-9]+\.[0-9]+%" |cut -d'>' -f2|sed 's/<//g' |tr '\n' ' ')    
  cap=$(curl -s  "https://www.tipranks.com/api/stocks/getData/?name=$ticker" |jq .marketCap)  
  [[ $cap -gt $MARKET_CAP ]] && echo -e $line" "$etf_weight |awk '{printf("%5s%8s%8s%8s\n",$1,$2,$3,$4)}'
done

#cat foolrecentpick.csv |awk -F',' '{if ($4>90.00) print $0}' |egrep -v '<20' |cut -d',' -f1 |sort |uniq -c |sort -nr |egrep -v '\s+1' 