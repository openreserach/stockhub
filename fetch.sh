#!/bin/sh

./fool.sh
./seekingalphalong.sh
./marketwatchgames.sh
curl -s https://www.gurufocus.com/guru/latest-picks |egrep -B 50 'days ago'  |awk '/^Buy:/,/^Add:/' |egrep -v 'Buy:|Add:|<'  >  gurufocus.csv
curl -s https://www.gurufocus.com/guru/latest-picks |egrep -B 50 'days ago'  |awk '/^Add:/,/^Sell:/'|egrep -v 'Add:|Sell:|<' >> gurufocus.csv

> whalewisdom.csv
curl -s --http2 https://whalewisdom.com/filing/latest_filings |egrep -o '/filer/.+"' |sed 's/"//g' |while read filer
do
  curl -s --http2 https://whalewisdom.com//$filer |egrep -A 50 "Top Buys" |egrep "<strong>" |cut -d'>' -f3-  |while read buy
  do
    echo $buy","$filer >> whalewisdom.csv
  done
done