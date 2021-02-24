#!/bin/bash

shopt -s expand_aliases
alias mycurl="curl -s --max-time 10 -L -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' --ipv4 --http2 --compressed"

echo "Economic & Market Overview===================="
#ref: https://en.wikipedia.org/wiki/Price%E2%80%93earnings_ratio#Historical_P/E_ratios_for_the_U.S._stock_market
echo -e "S&P500 PE Average:\t\t\t\t"$(mycurl https://www.multpl.com/ |egrep -o "Current S&P 500 PE Ratio is [0-9.]+" |rev |awk '{print $1}' |rev)
#ref:https://en.wikipedia.org/wiki/Greed_and_fear 
echo -e "FearGreed (0-100):\t\t\t\t"$(mycurl "https://money.cnn.com/data/fear-and-greed/" |egrep -o "Fear.+Greed Now: [0-9]+ [(A-Za-z ]+" |cut -d":" -f2 |sed "s/^ //g")")"
#ref: https://www.investopedia.com/ask/answers/06/putcallratio.asp
pagedump=$(mycurl "https://markets.cboe.com/us/options/market_statistics/daily/" |egrep -A 1 '>INDEX PUT/CALL RATIO<|>EQUITY PUT/CALL RATIO<' |egrep -o '>[0-9].[0-9]+<' |sed -e 's/>//g' -e 's/<//g')
echo -e "Index  Put/Call Ratio:\t\t\t"$(echo $pagedump|awk '{print $1}')
echo -e "Equity Put/Call Ratio:\t\t\t"$(echo $pagedump|awk '{print $2}') 
echo -e "VIX(daily+/-change):\t\t\t"$(mycurl "https://www.cboe.com/tradable_products/vix/quote/" |jq -r ".data.quote,.data.prev_close"  |tr '\n' ' ' |awk '{print $1,$1-$2}')

echo -e "Personal Saving Rate:\t\t\t"$(mycurl "https://fred.stlouisfed.org/series/PSAVERT" |egrep '20[0-9]+: <span class="series-meta-observation-value' |sed -e 's/: <span class="series-meta-observation-value">/ /g' |cut -d'<' -f1|sed 's/^[[:space:]]*//g' |awk '{print $3}')"%"   
echo -e "Crash Index:\t\t\t"$(mycurl https://www.quandl.com/api/v3/datasets/YALE/US_CONF_INDEX_CRASH_INDIV/data?collapse=monthly |jq -r ".dataset_data.data[0][1]")
echo -e "Customer Securities Debit:\t\t"$(mycurl https://www.finra.org/investors/learn-to-invest/advanced-investing/margin-statistics |egrep -m 1 -B 50 '<\/tbody>' |egrep -A 50 "<th>Month/Year</th>" |tac |head -n 4|egrep "Debit Balances"  |cut -d'>' -f2 |cut -d'<' -f1) 
#ref:https://www.gurufocus.com/stock-market-valuations.php
mycurl "https://www.gurufocus.com/stock-market-valuations.php" |egrep -o "Banks\s+\(currently at .+ a year" |egrep -o "[-0-9.]+%" |tr '\n' ' ' \
  |awk '{ if ($1>1.00) print "Buffett Indicator:\t\t\t\t\033[31m"$1"%\033[0m and 1 year return "$2 ; else print "Buffett Indicator:\t\t\t\t"$1" and 1 year return "$2}'
#ref:https://www.financialresearch.gov/financial-stress-index/
mycurl "https://www.financialresearch.gov/financial-stress-index/data/fsi.json" | jq -r ".OFRFSI.data[-1][1]" \
  | awk '{if ($1>0) print "OFR Financial Stress Index:\t\t\033[31m"$1"%\033[0m"; else print "OFR Financial Stress Index:\t\t"$1;}'
mycurl "https://finance.yahoo.com/quote/%5ETNX/" |egrep -o 'data-reactid="33">[0-9.]+' |cut -d'>' -f2 \
  | awk '{if ($1>1.5) print "Treasury Yield 10yr:\t\t\t\033[31m"$1"%\033[0m"; else print "Treasury Yield 10yr:\t\t\t"$1;}' 
echo -e "AAII Bullish|Neutral|Bearish:\t"$(mycurl -c tmp 'https://www.aaii.com/sentimentsurvey' |egrep -m 3 "bar bullish|bar neutral|bar bearish"|cut -d'>' -f2 |cut -d'<' -f1 |tr '\n' '|')
#TODO:...

tar -czf lastfetch.tar.gz *.csv #can diff holding between today and yesterday by zgrep -a -w <ticker> yesterday.tar.gz
rm -f *.csv tmp*

echo -n "tipranks"; >tipranks.csv
mycurl "https://www.tipranks.com/api/experts/getTop25Experts/?expertType=10&numExperts=100" |jq -r '.[] | .expertPortfolioId' |while read id
do #TipRank TOP 100 *Public* Portfolio
  echo -n "."
	mycurl "https://www.tipranks.com/api/publicportfolio/getportfoliobyid/?id=$id" |jq -r '.holdings[] |select (.weight >= 0.01) | .ticker ' |while read ticker
	do #with holding weight > 5%
		echo "https://www.tipranks.com/investors/"$id,$ticker >> tipranks.csv 
  done
done

echo -n "motleyfool"; >foolrecentpick.csv #MotleyFool players recent trading 
seq 0 49 |while read pagenum 
do #Fool's player's recent (in the most recent 50 pages) picks
  echo -n "."
  url='https://caps.fool.com/Ajax/GetPickStats.aspx?pagenum='$pagenum'&filter=40&sortcol=4&sortdir=1'
  mycurl $url |sed 's/None/0.0/g' | egrep -o 'href="/Ticker/[A-Z]+.aspx|ratings/foolcaps_[a-z]+.gif|href="/player/[A-Za-z0-9\-]+.aspx|PlayerRating">.+[0-9.]+<|[0-9]+/[0-9]+/[0-9]+$' |tr -d '\n' |sed -e 's/href="\/Ticker\//\n/g' -e 's/.aspxratings\/foolcaps_/,/g' -e 's/.gifhref="\/player\//,/g' -e 's/.aspxPlayerRating">/,/g' -e 's/</,/g' -e 's/none/0/g' -e 's/one/1/g' -e 's/two/2/g' -e 's/three/3/g' -e 's/four/4/g' -e 's/five/5/g' -e s'/&lt; /</g' |grep . >> foolrecentpick.csv
done

#whalewisdom.com 13F latest filler 
echo -n "13F"; >whalewisdom.csv
mycurl https://whalewisdom.com/filing/latest_filings |egrep -o '/filer/.+"' |cut -d'/' -f3 |sed 's/"//g' |while read filer
do
  echo -n "."  
  performance=$(mycurl "https://whalewisdom.com/filer/$filer" |egrep -A 1 -B 3 "Performance Last 4 Quarters" |egrep -o "[0-9.]+%|-[0-9.]+%" |tr '\n' ',')  
  mycurl "https://whalewisdom.com/filer/holdings?id=$filer&limit=100" |jq -r '.rows[]|[.symbol, .position_change_type] |@csv' |sed 's/"//g' |egrep "new|addition|reduction|soldall" |while read position 
  do    
    echo $position","$filer","$performance >> whalewisdom.csv    
  done
done

echo -n "ARK"; >ark.csv; ARK_CSV_URL="https://ark-funds.com/wp-content/fundsiteliterature/csv"
mycurl "$ARK_CSV_URL/ARK_INNOVATION_ETF_ARKK_HOLDINGS.csv"                       |egrep ARKK |cut -d',' -f2,4 |egrep -v "ARKK,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/ARK_NEXT_GENERATION_INTERNET_ETF_ARKW_HOLDINGS.csv"         |egrep ARKW |cut -d',' -f2,4 |egrep -v "ARKW,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/ARK_AUTONOMOUS_TECHNOLOGY_&_ROBOTICS_ETF_ARKQ_HOLDINGS.csv" |egrep ARKQ |cut -d',' -f2,4 |egrep -v "ARKQ,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/ARK_FINTECH_INNOVATION_ETF_ARKF_HOLDINGS.csv"               |egrep ARKF |cut -d',' -f2,4 |egrep -v "ARKF,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/ARK_GENOMIC_REVOLUTION_MULTISECTOR_ETF_ARKG_HOLDINGS.csv"   |egrep ARKG |cut -d',' -f2,4 |egrep -v "ARKG,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/THE_3D_PRINTING_ETF_PRNT_HOLDINGS.csv"                      |egrep PRNT |cut -d',' -f2,4 |egrep -v "PRNT,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv
mycurl "$ARK_CSV_URL/ARK_ISRAEL_INNOVATIVE_TECHNOLOGY_ETF_IZRL_HOLDINGS.csv"     |egrep IZRL |cut -d',' -f2,4 |egrep -v "IZRL,$" |sed 's/"//g' |awk '{print $1}' >> ark.csv

#SeekingAlpha Latest Long ideas
mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+" |sed -n '1!p'  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]' > seekingalphalong.csv

#Gurufocus latest picks
mycurl https://www.gurufocus.com/guru/latest-picks |egrep '^Buy:|^Add:|Sell:|^Reduce:|^[A-Z]{1,5}$' |egrep -v "USA|RSS|FAQ|API|ETF" |egrep  '^[A-Z]+' |tr '\n' ',' |sed -e's/,Buy:/\nBuy:/g' -e 's/,Reduce:/\nReduce:/g' -e 's/,Sell:/\nSell:/g' -e 's/,Add:/\nAdd:/g' |sed 's/:,/:/g' |egrep -v ':$' > gurufocus.csv

#Barron's pick
mycurl "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |egrep -v '^$' > barrons.csv

#Insider recent buys
mycurl "https://finviz.com/insidertrading.ashx?tc=1" |egrep "screener.ashx\?" |cut -d'=' -f5- |cut -d'"' -f1 |tr ',' '\n' > insiderbuy.csv

echo -n "simplywallstreet"; >simplywallstreet.csv
mycurl 'https://simplywall.st/discover/investing-ideas' |egrep -o '/discover/investing-ideas/[0-9]+/[a-z-]+' |while read uri
do
  echo -n "."
  idea=$(echo $uri |cut -d'/' -f5)
  mycurl  "https://simplywall.st$uri" |egrep -o "NYSE:[A-Z]+|NasdaqG[A-Z]:[A-Z]+" |cut -d':' -f2 |sort |uniq |while read ticker
  do
    echo $ticker,$idea >> simplywallstreet.csv
  done
done

#echo -n "youtuber"; >youtubers.csv
#for youtuber in graham-stephan stock-moe jeremy-lefebvre-financial-education meet-kevin-paffrath george-perez chris-sain-jr \                                                                                    lets-talk-money-with-joseph-hogue-cfa jack-spencer-investing darcy-macdonald kenan-grace beatthebush-francis
#do
#  echo -n "."
#  mycurl  "https://finvid-recap.com/profiles/$youtuber" |egrep -o 'data-opts=.+' |cut -d';' -f4 |cut -d'&' -f1 |while read holding
#    do
#      echo $youtuber,$holding >> youtubers.csv
#    done
#done

#Marketwatch stock trading games, contests and challenges
#>marketwatchgames.csv
#for game in lifetime-stock-market-game invest-until-you-die invest-until-you-die-two-2 invest-until-you-die-4 official-reddit-challenge-2020 trades-for-life 2020ueic 
#do #annually pick active games with more participants
#  for page in 0 10 20 30 40 50 
#  do #the latst 50 pages 
#	  mycurl "https://www.marketwatch.com/game/$game/rankings?partial=true&index=$page" |egrep -o "/game/$game/portfolio\?p=[0-9]+.+ class" |cut -d'"' -f1 |while read portfolio
#	  do
#      echo -n "."
#     name=$(echo $portfolio |egrep -o 'name=\S+' |cut -d'=' -f2 |sed 's/%20/ /g')#
#	    mycurl "https://www.marketwatch.com$portfolio" > tmp
#	    rank=$(cat tmp|egrep 'rank__number ">'  |cut -d'>' -f2 |cut -d'<' -f1)
#      cat tmp  |egrep -A 6 'mini-quote-tr' |cut -d'>' -f2- |tr -d "\r\n" |sed 's/--/\n/g' |sed 's/<\/td>/ /g' |awk '{print $1","$4","$6}' |while read holding
#	    do
#	      echo $holding,$rank,$portfolio >> marketwatchgames.csv
#	    done
#	  done
#  done
#done

[[  ! -z $(find . -name "*.csv" -type f -size 0) ]] && echo "Incomplete" || echo "Complete" 

./commonbuystocks.sh