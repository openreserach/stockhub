#!/bin/bash

shopt -s expand_aliases
alias mycurl="curl -s --max-time 5 -L -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' --ipv4 --http2 --compressed"

export FOOL_PLAYER_RATING=90.0  #percent
export MARKET_CAP=1000000000    #$1B 

#export GAMES_IN_RECENTDAY=14    #days 
#weekagoSec=$(date --date "$GAMES_IN_RECENTDAY days ago" +'%s')  
#cat marketwatchgames.csv |egrep ',Buy,' |sort |uniq |while read line
#do #recent buy in last N days
#  transactionDate=$(echo $line |cut -d',' -f2)
#  transactionSec=$(date --date "$transactionDate" +'%s')
#  [ $transactionSec -gt $weekagoSec ] && echo $line |cut -d',' -f1 >> tmp  
#done 
#cat youtubers.csv        |cut -d',' -f2 |sort |uniq >> tmp                             #Distinct youtuber's picks

>tmp
cat gurufocus.csv         |egrep "Buy:|Add:" |cut -d':' -f2 |tr ',' '\n'>>tmp           #Guru's recent Buy/Add
cat ark.csv |egrep '^ARK' |cut -d',' -f2 |sort |uniq |egrep '[A-Z]+' >> tmp             #all ARK* invenstment holdings
cat insiderbuy.csv                       |sort |uniq >> tmp                             #Lastest buy by insiders
cat seekingalphalong.csv                             >> tmp                             #Seekingalpha Long
cat foolrecentpick.csv    |awk -F',' '{if( $4>'$FOOL_PLAYER_RATING'){print $1}}'|sort   >> tmp   #FOOL high rating players' picks
cat whalewisdom.csv       |egrep ",new,|,addition," |cut -d',' -f1 |sort |uniq -c |sort -nr |head -n 100 |awk '{print $2}' >> tmp #13F new/addition TOP-100 HEATMAP
cat tipranks.csv          |cut -d',' -f2 |sort |uniq -c |sort -nr |head -n 100 |awk '{print $2}' >> tmp #tiprank investors' TOP-100 HEATMAP

echo "Sources Ticker    ETF   Weight"  >tmpcommon
#cat tmp |sort |uniq -c |sort -nr | egrep -v '\s+1\s|\s+1\s' |while read line
cat tmp |sort |uniq -c |sort -nr | egrep -v '\s+1\s' |while read line
do
  count=$(echo $line |awk '{print $1}')
  ticker=$(echo $line |awk '{print $2}')
  etf_weight=$(egrep -w "^$ticker" stock-etf-weight.lst) 
  [[ $etf_weight ]] && echo $count" "$etf_weight |awk '{printf("%5s%8s%8s%8s\n",$1,$2,$3,$4)}' >> tmpcommon 
done

echo "ETF play: ETFs exposed to commonly selected stocks sorted by combined weights" >tmp 
cat tmpcommon |awk '{print $3}'|egrep -v '^$'|sort|uniq -c|sort -nr | egrep -v 'ARK' |while read line
do
  etf=$(echo $line |awk '{print $2}')  
  total_weight=$(egrep $etf tmpcommon |awk '{print $4}' | awk '{sum+=$0}END{print sum"%"}')  
  echo $line" "$total_weight |awk '{print $3" "$1" "$2}' >> tmp
done
echo "Weights    ETF    Count"
cat tmp |sort -nr |head -n 20  |awk '{printf("%8s%6s%5s\n",$1,$3,$2)}'
echo "-----------------------------------------"

echo "Fool Play: Multiple fool players buy"
cat foolrecentpick.csv |egrep '9[0-9]\.[0-9]+' |cut -d',' -f1 |sort |uniq -d |tr '\n' ',';echo
echo "-----------------------------------------"

echo "Tipranks Play:Tipranks Top players intraday new positions"
diff -a <(cat tipranks.csv |sort) <(zcat lastfetch.tar.gz |egrep -a -o 'https://www.tipranks.+' |sort ) |egrep -a "<" |cut -d',' -f2 |tr '\n' ',';echo
echo "-----------------------------------------"

echo "ARK Play: Stocks newly added to ARK"
> tmp 
for ark in ARKK ARKG ARKW ARKQ ARKF
do
  mycurl "https://www.arktrack.com/$ark.json" | jq -r '.[]|.ticker'  |sort |uniq -c |sort -n |head |awk '{if ($1<10) print $2}' >> tmp
done
cat tmp |sort |uniq |tr '\n' ',';echo
echo "-----------------------------------------"