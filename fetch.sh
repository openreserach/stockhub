#!/bin/sh

./fool.sh
./seekingalphalong.sh
./marketwatchgames.sh
curl -s https://www.gurufocus.com/guru/latest-picks |egrep -B 50 'days ago'  |awk '/^Buy:/,/^Add:/' |egrep -v 'Buy:|Add:|<'  >  gurufocus.csv
curl -s https://www.gurufocus.com/guru/latest-picks |egrep -B 50 'days ago'  |awk '/^Add:/,/^Sell:/'|egrep -v 'Add:|Sell:|<' >> gurufocus.csv