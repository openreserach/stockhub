#!/bin/sh

./fool.sh
./seekingalphalong.sh
./marketwatchgames.sh

curl -s https://www.gurufocus.com/guru/latest-picks |awk '/^Buy:/,/^Add:|^Sell:|^Reduce:/' |egrep -v 'Buy|Add|Sell|Reduce|<'     > gurufocus.csv
curl -s https://www.gurufocus.com/guru/latest-picks |awk '/^Add:/,/^Sell:|^Reduce:|ago/'   |egrep -v 'Buy|Add|Sell|Reduce|<|ago'>> gurufocus.csv

> whalewisdom-new.csv #new positions
> whalewisdom-add.csv #added to existing positions
curl -s --http2 https://whalewisdom.com/filing/latest_filings |egrep -o '/filer/.+"' |cut -d'/' -f3 |sed 's/"//g' |while read filer
do
  curl -s --http2 "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=1&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=source_date&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read new
  do
    echo $new","$filer >> whalewisdom-new.csv
  done
  curl -s --http2 "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=2&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=current_mv&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read add
  do
    echo $add","$filer >> whalewisdom-add.csv
  done
done