#!/bin/bash

mycurl="curl -s --max-time 3 -L -k --ipv4 -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0'"

echo "Market Overview=============="
echo -e "S&P500 PE Average:\t\t"$($mycurl https://www.multpl.com/ |egrep -o "Current S&P 500 PE Ratio is [0-9.]+" |rev |awk '{print $1}' |rev)
echo -e "FearGreed (0-100):\t\t"$($mycurl "https://money.cnn.com/data/fear-and-greed/" |egrep -o "Fear.+Greed Now: [0-9]+ [(A-Za-z ]+" |cut -d":" -f2 |sed "s/^ //g")")"
$mycurl "https://markets.cboe.com/us/options/market_statistics/daily/" |egrep -A 1 '>INDEX PUT/CALL RATIO<|>EQUITY PUT/CALL RATIO<' |egrep -o '>[0-9].[0-9]+<' |sed -e 's/>//g' -e 's/<//g' > tmp
echo -e "Index  Put/Call Ratio:\t"$(head -n 1 tmp)
echo -e "Equity Put/Call Ratio:\t"$(tail -n 1 tmp) 
echo -e "Personal Saving Rate:\t"$($mycurl "https://fred.stlouisfed.org/series/PSAVERT" |egrep '20[0-9]+: <span class="series-meta-observation-value' |sed -e 's/: <span class="series-meta-observation-value">/ /g' |cut -d'<' -f1|sed 's/^[[:space:]]*//g')"%"   
echo -e "Crash Index:\t\t\t"$($mycurl https://www.quandl.com/api/v3/datasets/YALE/US_CONF_INDEX_CRASH_INDIV/data?collapse=monthly |jq ".dataset_data.data[0]"  |tail -n +3 |head -n 1|sed -e 's/ //g' -e 's/,//g')
#TODO:VIX, ...


rm -f *.csv tmp*
#MotleyFool players recent trading 
>foolrecentpick.csv
seq 0 49 |while read pagenum 
do #Fool's player's recent (in the most recent 50 pages) picks
  echo -n "."
  url='https://caps.fool.com/Ajax/GetPickStats.aspx?rand=780489512&objid=divTopTenListforTickersAjax&pagenum='$pagenum'&filter=40&sortcol=4&sortdir=1&pgid=0&ref=https%3A//caps.fool.com/stats.aspx'
  $mycurl $url |sed 's/None/0.0/g' | egrep -o 'href="/Ticker/[A-Z]+.aspx|ratings/foolcaps_[a-z]+.gif|href="/player/[A-Za-z0-9\-]+.aspx|PlayerRating">.+[0-9.]+<|[0-9]+/[0-9]+/[0-9]+$' |tr -d '\n' |sed -e 's/href="\/Ticker\//\n/g' -e 's/.aspxratings\/foolcaps_/,/g' -e 's/.gifhref="\/player\//,/g' -e 's/.aspxPlayerRating">/,/g' -e 's/</,/g' -e 's/none/0/g' -e 's/one/1/g' -e 's/two/2/g' -e 's/three/3/g' -e 's/four/4/g' -e 's/five/5/g' -e s'/&lt; /</g' |grep . >> foolrecentpick.csv
done

#Marketwatch stock trading games, contests and challenges
>marketwatchgames.csv
for game in lifetime-stock-market-game invest-until-you-die invest-until-you-die-two-2 invest-until-you-die-4 official-reddit-challenge-2020 trades-for-life 2020ueic 
do #annually pick active games with more participants
  for page in 0 10 20 30 40 50 
  do #the latst 50 pages 
	  $mycurl "https://www.marketwatch.com/game/$game/rankings?partial=true&index=$page" |egrep -o "/game/$game/portfolio\?p=[0-9]+.+ class" |cut -d'"' -f1 |while read portfolio
	  do
      echo -n "."
 	    name=$(echo $portfolio |egrep -o 'name=\S+' |cut -d'=' -f2 |sed 's/%20/ /g')
	    $mycurl "https://www.marketwatch.com$portfolio" > tmp
	    rank=$(cat tmp|egrep 'rank__number ">'  |cut -d'>' -f2 |cut -d'<' -f1)
      cat tmp  |egrep -A 6 'mini-quote-tr' |cut -d'>' -f2- |tr -d "\r\n" |sed 's/--/\n/g' |sed 's/<\/td>/ /g' |awk '{print $1","$4","$6}' |while read holding
	    do
	      echo $holding,$rank,$portfolio >> marketwatchgames.csv
	    done
	  done
  done
done

#SeekingAlpha Latest Long ideas
$mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+" |sed -n '1!p'  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]' > seekingalphalong.csv

#Gurufocus latest picks
$mycurl https://www.gurufocus.com/guru/latest-picks |egrep '^Buy:|^Add:|Sell:|^Reduce:|^[A-Z]{1,5}$' |egrep -v "USA|RSS|FAQ|API|ETF" |egrep  '^[A-Z]+' |tr '\n' ',' |sed -e's/,Buy:/\nBuy:/g' -e 's/,Reduce:/\nReduce:/g' -e 's/,Sell:/\nSell:/g' -e 's/,Add:/\nAdd:/g' |sed 's/:,/:/g' |egrep -v ':$' > gurufocus.csv

#whalewisdom.com guru recent positions 
> whalewisdom-new.csv #new positions
> whalewisdom-add.csv #added to existing positions
$mycurl https://whalewisdom.com/filing/latest_filings |egrep -o '/filer/.+"' |cut -d'/' -f3 |sed 's/"//g' |while read filer
do
  echo -n "."
  performance=$($mycurl "https://whalewisdom.com/filer/$filer" |egrep -A 1 -B 3 "Performance Last 4 Quarters" |egrep -o "[0-9.]+%|-[0-9.]+%" |tr '\n' ',')
  $mycurl "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=1&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=source_date&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read new
  do
    echo $new","$filer","$performance >> whalewisdom-new.csv
  done
  $mycurl "https://whalewisdom.com/filer/holdings?id=$filer&q1=-1&type_filter=1,2,3,4&symbol=&change_filter=2&minimum_ranking=&minimum_shares=&is_etf=0&sc=true&sort=current_mv&order=desc&offset=0&limit=50" |jq ".rows[].symbol" |sed 's/"//g'| while read add
  do
    echo $add","$filer","$performance >> whalewisdom-add.csv
  done
done

>ark.csv; echo "."
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_INNOVATION_ETF_ARKK_HOLDINGS.csv"                       |egrep ARKK |cut -d',' -f2,4 |egrep -v "ARKK,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_NEXT_GENERATION_INTERNET_ETF_ARKW_HOLDINGS.csv"         |egrep ARKW |cut -d',' -f2,4 |egrep -v "ARKW,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_AUTONOMOUS_TECHNOLOGY_&_ROBOTICS_ETF_ARKQ_HOLDINGS.csv" |egrep ARKQ |cut -d',' -f2,4 |egrep -v "ARKQ,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_FINTECH_INNOVATION_ETF_ARKF_HOLDINGS.csv"               |egrep ARKF |cut -d',' -f2,4 |egrep -v "ARKF,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_GENOMIC_REVOLUTION_MULTISECTOR_ETF_ARKG_HOLDINGS.csv"   |egrep ARKG |cut -d',' -f2,4 |egrep -v "ARKG,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/THE_3D_PRINTING_ETF_PRNT_HOLDINGS.csv"                      |egrep PRNT |cut -d',' -f2,4 |egrep -v "PRNT,$" >> ark.csv
$mycurl "https://ark-funds.com/wp-content/fundsiteliterature/csv/ARK_ISRAEL_INNOVATIVE_TECHNOLOGY_ETF_IZRL_HOLDINGS.csv"     |egrep IZRL |cut -d',' -f2,4 |egrep -v "IZRL,$" >> ark.csv

[[  $(find . -name "*.csv" -type f -size 0) == 0 ]] && echo "Incomplete" || echo "Complete" 