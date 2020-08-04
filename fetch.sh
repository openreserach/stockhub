#!/bin/bash

#MotleyFool players' recent trading 
>foolrecentpick.csv
seq 0 49 |while read pagenum 
do #Fool's player's recent (in the most recent 50 pages) picks
  url='https://caps.fool.com/Ajax/GetPickStats.aspx?rand=780489512&objid=divTopTenListforTickersAjax&pagenum='$pagenum'&filter=40&sortcol=4&sortdir=1&pgid=0&ref=https%3A//caps.fool.com/stats.aspx'
  curl -s $url |sed 's/None/0.0/g' | egrep -o 'href="/Ticker/[A-Z]+.aspx|ratings/foolcaps_[a-z]+.gif|href="/player/[A-Za-z0-9\-]+.aspx|PlayerRating">.+[0-9.]+<|[0-9]+/[0-9]+/[0-9]+$' |tr -d '\n' |sed -e 's/href="\/Ticker\//\n/g' -e 's/.aspxratings\/foolcaps_/,/g' -e 's/.gifhref="\/player\//,/g' -e 's/.aspxPlayerRating">/,/g' -e 's/</,/g' -e 's/none/0/g' -e 's/one/1/g' -e 's/two/2/g' -e 's/three/3/g' -e 's/four/4/g' -e 's/five/5/g' -e s'/&lt; /</g' |grep . >> foolrecentpick.csv
done

#Marketwatch stock trading games, contests and challenges
>marketwatchgames.csv
for game in lifetime-stock-market-game invest-until-you-die invest-until-you-die-two-2 invest-until-you-die-4 official-reddit-challenge-2020 trades-for-life 2020ueic 
do #annually pick active games with more participants
  for page in 0 10 20 30 40 50 
  do #the latst 50 pages 
	  curl -s -L "https://www.marketwatch.com/game/$game/rankings?partial=true&index=$page" |egrep -o "/game/$game/portfolio\?p=[0-9]+.+ class" |cut -d'"' -f1 |while read portfolio
	  do
 	    name=$(echo $portfolio |egrep -o 'name=\S+' |cut -d'=' -f2 |sed 's/%20/ /g')
	    curl -s "https://www.marketwatch.com/"$portfolio > tmp
	    rank=$(cat tmp|egrep 'rank__number ">'  |cut -d'>' -f2 |cut -d'<' -f1)
	    cat tmp  |egrep -A 9 '</mini-quote>' |egrep -o '[A-Z0-9]+<\/mini-quote>|class="primary">[0-9]+%|class="text">[A-Za-z]+' |cut -d'<' -f1 |cut -d'>' -f2 |tr  '\n' ',' |sed -e 's/Buy/Buy\n/g' -e 's/Short/Short\n/g' |sed 's/^,//g' |while read holding
	    do
	      echo $holding,$rank,$portfolio >> marketwatchgames.csv
	    done
	  done
  done
done

#SeekingAlpha Latest Long ideas
curl -s -A 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1' "https://seekingalpha.com/stock-ideas/long-ideas" \
|grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]' > seekingalphalong.csv

#Gurufocus latest picks
curl -s https://www.gurufocus.com/guru/latest-picks |awk '/^Buy:/,/^Add:|^Sell:|^Reduce:/' |egrep -v 'Buy|Add|Sell|Reduce|<'     > gurufocus.csv
curl -s https://www.gurufocus.com/guru/latest-picks |awk '/^Add:/,/^Sell:|^Reduce:|ago/'   |egrep -v 'Buy|Add|Sell|Reduce|<|ago'>> gurufocus.csv

#whalewisdom.com guru recent positions 
> whalewisdom-new.csv #new positions
> whalewisdom-add.csv #added to existing positions
curl -s https://whalewisdom.com/filing/latest_filings |egrep -o '/filer/.+"' |cut -d'/' -f3 |sed 's/"//g' |while read filer
do
  curl -s "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=1&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=source_date&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read new
  do
    echo $new","$filer >> whalewisdom-new.csv
  done
  curl -s "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=2&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=current_mv&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read add
  do
    echo $add","$filer >> whalewisdom-add.csv
  done
done