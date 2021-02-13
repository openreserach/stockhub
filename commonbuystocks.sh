#!/bin/bash

shopt -s expand_aliases
alias mycurl="curl -s --max-time 5 -L -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' --ipv4 --http2 --compressed"

export MARKETWATCH="marketwatchgames.csv"
export FOOLPICKS="foolrecentpick.csv" 
export GAMES_IN_RECENTDAY=14    #days 
export FOOL_PLAYER_RATING=90.0  #percent
export MARKET_CAP=1000000000    #$1B 

>tmp
cat $MARKETWATCH |egrep ',Buy,' |sort |uniq |while read line
do #recent buy in last N days
  transactionDate=$(echo $line |cut -d',' -f2)
  transactionSec=$(date --date "$transactionDate" +'%s')   
  weekagoSec=$(date --date "$GAMES_IN_RECENTDAY days ago" +'%s')  
  [ $transactionSec -gt $weekagoSec ] && echo $line |cut -d',' -f1 >> tmp  
done 

mycurl "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |cut -d',' -f1 |egrep -v '^$' |sort |uniq >> tmp  #Barron's pick
cat $FOOLPICKS  |awk -F',' '{if( $4>'$FOOL_PLAYER_RATING'){print $1}}'|sort     >> tmp  #FOOL high rating players' picks
cat seekingalphalong.csv  |sort >> tmp                                                  #recent(~2days) LONG recommendation by seekingalpha
cat gurufocus.csv         |egrep "Buy:|Add:" |cut -d':' -f2 |tr ',' '\n'>>tmp           #Guru's recent Buy/Add
cat whalewisdom-add.csv   |cut -d',' -f1 |sort |uniq  >> tmp                            #13F recent filers' new position
cat whalewisdom-new.csv   |cut -d',' -f1 |sort |uniq  >> tmp                            #13F recent filer's add position
cat ark.csv |egrep '^ARK' |cut -d',' -f2 |sort |uniq |egrep '[A-Z]+' >> tmp             #all ARK* invenstment holdings
cat youtubers.csv         |cut -d',' -f2 |sort |uniq >> tmp                             #Distinct youtuber's picks
cat tipranks.csv          |cut -d',' -f2 |sort |uniq >> tmp 
cat barrons.csv           |cut -d',' -f1 |sort |uniq >> tmp 
cat insiderbuy.csv                       |sort |uniq >> tmp

echo "Sources Ticker    ETF   Weight"  >tmpcommon
cat tmp |sort |uniq -c |sort -nr | egrep -v '\s+1\s|\s+2\s' |while read line
do
  count=$(echo $line |awk '{print $1}')
  ticker=$(echo $line |awk '{print $2}')
  etf_weight=$(egrep -w "^$ticker" stock-etf-weight.lst) 
  [[ $etf_weight ]] && echo $count" "$etf_weight |awk '{printf("%5s%8s%8s%8s\n",$1,$2,$3,$4)}' >> tmpcommon 
done

>tmp #ETFs exposure to commonly selected stocks with combined weights
cat tmpcommon |awk '{print $3}'|egrep -v '^$'|sort|uniq -c|sort -nr | egrep -v 'ARK' |while read line
do
  etf=$(echo $line |awk '{print $2}')  
  total_weight=$(egrep $etf tmpcommon |awk '{print $4}' | awk '{sum+=$0}END{print sum"%"}')  
  echo $line" "$total_weight |awk '{print $3" "$1" "$2}' >> tmp
done
echo "Weights    ETF    Count"
cat tmp |sort -nr |head -n 20  |awk '{printf("%8s%6s%5s\n",$1,$3,$2)}'