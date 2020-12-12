#!/bin/bash

mycurl="curl -s --max-time 3 -L -k --ipv4 --http2 -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0'"
set -- $(echo $1 |tr [:lower:] [:upper:]) #reset ticker to upper case
FOOL="foolrecentpick.csv"
GAMES="marketwatchgames.csv"
WHALEWISDOM="whalewisdom*.csv"
ARK="ark.csv"
GURUFOCUS="gurufocus.csv"

$mycurl "https://www.finviz.com/quote.ashx?t=$1" > tmp
cat tmp|grep "<title>" |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/Stock Quote//g'
cat tmp|grep center |grep fullview-links |grep tab-link |cut -d'>' -f4,6,8 |sed 's/<\/a/ /g'

price=$(cat tmp |egrep "Current stock price" |egrep -o '>[0-9.]+<' |cut -d'>' -f2 |cut -d'<' -f1)
updown=$(cat tmp |egrep "Change</td>" |egrep -o '>[0-9.]+%<|>\-[0-9.]+%<' |cut -d'>' -f2 |cut -d'<' -f1)
echo "$"$price $updown `date +%x`
echo "FA color-coded=============================="
for key in 'Market Cap' 'P/E' 'Forward P/E' 'P/S' 'P/B' 'PEG' 'P/FCF' 'Quick Ratio' 'Debt/Eq' 'ROE' 'SMA20' 'Target Price' 'Recom' 'Beta' 'Inst Own' 'Dividend %' 'Earnings' 
do
	color=$(cat tmp |grep ">$key<" |egrep -o "is-red|is-green")
	val=$(cat tmp |grep ">$key<" |egrep -o ">[0-9]+.[0-9]+<|>[0-9]+.[0-9]+B<|>[0-9]+.[0-9]+M<|>[0-9]+.[0-9]+%<|[A-Z][a-z]+ [0-9]+|[0-9]+.[0-9]+%|>-<" |tail -n 1 |sed -e 's/>//g' -e 's/<//g' -e 's/-//g')
  [[ $color == 'is-red'   && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s%-10s\n"),$1,$2}'  | awk  '{ print "\033[31m"$0"\033[0m";}'
  [[ $color == 'is-green' && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s%-10s\n"),$1,$2}'  | awk  '{ print "\033[32m"$0"\033[0m";}'
  [[ -z $color            && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s%-10s\n"),$1,$2}'
done
$mycurl "https://finance.yahoo.com/quote/$1/key-statistics?p=$1"|sed 's/td/\n/g'|egrep data-reactid |egrep -A 1 "Enterprise Value/EBITDA" |tail -n 1 |egrep -o '>[0-9]+.[0-9]+<' |sed -e 's/>//g' -e 's/<//g' |awk '{printf("EV/EBITDA      %3.2f\n",$1)}'
etf=$($mycurl "https://etfdb.com/stock/$1/"|egrep Ticker|egrep Weighting|head -n 1 |egrep -o "href=\"/etf/[A-Z]+/\">[A-Z]+<|Weighting\">[0-9]+\.[0-9]+%"|cut -d'>' -f2|sed 's/<//g' |tr '\n' ' ')
[[ ! -z $etf ]] && echo $etf | awk '{printf("ETF/Weight     %-s/%2.2f%%\n",$1,$2)}' 

$mycurl https://finviz.com/insidertrading.ashx |sed 's/tr/\n/g' |egrep -w "t=$1" |egrep -o ">Buy<|>Sale<|>Option Exercise<" |sed -e 's/>//g' -e 's/<//g' |while read buysell
do
  echo -e "Insider:\t\t$buysell"
done
$mycurl https://finviz.com |egrep -w -A 5 $1 |egrep -B 5 -o "Stocks with .+"  |cut -d']' -f1
echo "News=================================="
cat tmp |egrep "white-space:nowrap" |head -n 3 |egrep -o 'white-space:nowrap">\S+.+tab-link-news">.+</a>' |cut -d'>' -f2,7  |cut -c1-10,35- |cut -d'<' -f1

echo "Rating================================"
#gurufocus Financial Strength & Profitability Strength
export FinancialStrength=$($mycurl https://www.gurufocus.com/stock/$1/summary |egrep -A 2 'Financial Strength' |egrep -A 1 fc-regular  |egrep "[0-9]+/10")
[[ ! -z $FinancialStrength ]] && echo -e "Strength:\t"$FinancialStrength
export Profitability=$($mycurl https://www.gurufocus.com/stock/$1/summary |egrep -A 2 'Profitability Rank' |egrep -A 1 fc-regular  |egrep "[0-9]+/10")
[[ ! -z $Profitability ]] && echo -e "ProfitRank:\t"$Profitability
export Valuation=$($mycurl https://www.gurufocus.com/stock/$1/summary |egrep -A 2 'Valuation Rank' |egrep -A 1 fc-regular  |egrep "[0-9]+/10")
[[ ! -z $Valuation ]] && echo -e "Valuation:\t"$Valuation

#Crammer's MadMoney comments
export dateratingprice=$($mycurl -s -d "symbol=$1" "https://madmoney.thestreet.com/07/index.cfm?page=lookup" |egrep -A 12  '>[0-9]+/[0-9]+/[0-9]+<' |egrep -o '[0-9]+/[0-9]+/[0-9]+|[0-9]+.gif|\$[0-9]+.[0-9]+|\$[0-9]+' |head -n 3 |sed 's/.gif//g' |tr '\n' ',')
[[ ! -z $dateratingprice ]] && echo -e "Crammer:\t"$dateratingprice |sed -e 's/,1,/,Sell,/g' -e 's/,2,/,Negative,/g' -e 's/,3,/,Neural,/g' -e 's/,4,/,Postive,/g' -e 's/,5,/,Buy,/g'


export zack=`$mycurl "https://www.zacks.com/stock/quote/$1" |egrep -m1 "rank_chip" |cut -d'<' -f1 |sed 's/ //g'`
[[ ! -z $zack ]] && echo -e "Zack Rank:\t"$zack
#stoxline rating
export stoxline=`$mycurl "http://m.stoxline.com/stock.php?symbol=$1" |grep -A 2 "Overall" |egrep "pics/[0-9]s.png" |egrep  -o '[0-9]s.png' |sed 's/s.png/ stars/g'`
[[ ! -z $stoxline ]] && echo -e "Stoxline:\t"$stoxline

#Argus Research from Yahoo
fairvalue=`$mycurl https://finance.yahoo.com/quote/$1  |egrep -o 'Fw\(b\) Fl\(end\)\-\-m Fz\(s\).+'|cut -c1-80 |cut -d'>' -f2 |cut -d'<' -f1`
[[ ! -z $fairvalue ]] && echo -e "Fair Value:\t"$fairvalue

#MotleyFool's rating. 
export motelyfool=$($mycurl https://caps.fool.com/Ticker/$1.aspx |egrep "capsStarRating" |head -n 1 |egrep -o "[0-9] out of 5")
[[ ! -z $motelyfool ]] && echo -e "MotelyFool:\t"$motelyfool

#tipranks
$mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq ".tipranksStockScore.score,.bloggerSentiment.bullish,.portfolioHoldingData.priceTarget, \
.portfolioHoldingData.analystConsensus.consensus,\
.portfolioHoldingData.analystConsensus.distribution.buy, \
.portfolioHoldingData.analystConsensus.distribution.hold, \
.portfolioHoldingData.analystConsensus.distribution.sell" |tr '\n' ','|sed 's/"//g' |\
awk -F',' '{printf("TR Score:   %d Bullish:%d%% Sentiment:%s\nPriceTarget:$%4.2f|Buy|Hold|Sell:%d|%d|%d\n"),$1,$2,$4,$3,$5,$6,$7}'

#Value Stock screening
curl -s "https://x-uni.com/api/screener-iv.php?params=30;;10000;;;;20;;;;;;;;;;;;;;;;;;;" |egrep -o "\"$1;" |sed "s/\"$1;/ValueScreen:\tIntrinsic Value/g"
curl -s 'https://x-uni.com/api/screener-gd.php?params=0.5;5;10;3;20;10' |egrep -o "\"$1;" |sed "s/\"$1;/ValueScreen:\tGraham-Dodd Stock/g"
curl -s 'https://x-uni.com/api/screener-gf.php?params=2;;4.6' |egrep -o "\"$1;" |sed "s/\"$1;/ValueScreen:\tGraham Formula Stock/g"

echo "TA & Trend ==================================="
$mycurl "https://www.stockta.com/cgi-bin/analysis.pl?symb="$1"&cobrand=&mode=stock" > tmp
trendspotter=`cat tmp |grep -i 'class="analysisTd' |grep -v Intermediate |egrep -o ">[A-Za-z]+ \([-0-9.]+\)" |tr '>' '|' |head -n 1 |cut -d'|' -f2`
candlestick=`cat tmp |egrep -A 2 CandleStick |egrep -o 'Recent CandleStick Analysis.+>[A-Za-z ]+|>Candle<.+borderTd">[A-Za-z ]+' |rev |cut -d'>' -f1 |rev |tr '\n' ' '`
[[ ! -z $trendspotter ]] && echo -e "Overall Trend:\t"$trendspotter
[[ ! -z $candlestick ]] && echo -e "Candle Stick:\t"$candlestick

export barchart=$($mycurl "https://www.barchart.com/stocks/quotes/$1/"  |egrep -o 'buy-color">[A-Za-z ]+</a>' |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/^ \+//g')
[[ ! -z $barchart ]] && echo -e "Chart Signal:\t"$barchart

#TA pattern
export signal= $($mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastSignal"  |egrep -o ">[A-Z ]+</font>" |cut -d'<' -f1|cut -d'>' -f2)
export pattern=$($mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastPattern" |cut -d'>' -f3 |cut -d'<' -f1  |sed 's/NO PATTERN//g' |tr -d '\r\n')
[[ ! -z $single  ]] && echo -e "USBull Signal\t"$signal
[[ ! -z $pattern ]] && echo -e "USBull Pattern\t"$pattern

pretiming=`$mycurl "https://www.pretiming.com/search?q=$1" |egrep -A 5  -m1 "Recommended Positions"  |tail -n 1 |egrep -o -i "long-bullish|long-bearish|short-bullish|short-bearish"`
[[ ! -z $pretiming ]] && echo -e "PreTiming TA:\t"$pretiming

oversold=`$mycurl "https://www.tradingview.com/markets/stocks-usa/market-movers-oversold"|egrep "window.initData.screener_data" |egrep -o "NYSE:[A-Z]+|NASDAQ:[A-Z]+|AMEX:[A-Z]+"|egrep -w $1`
[[ ! -z $oversold ]] && echo -e "TradingView:\tOversold"

shortinterest=$($mycurl https://www.highshortinterest.com/all/ |egrep -o "q?s=[A-Z\.]+" |cut -d'=' -f2 |egrep -i $1)
[[ ! -z $shortinterest ]] && echo -e "Short Interest:\tHigh"

echo "Radar Screen================================="
#Trading view
$mycurl https://www.tradingview.com/symbols/NYSE-$1 > tmp
$mycurl https://www.tradingview.com/symbols/NASDAQ-$1 >> tmp 
$mycurl https://www.tradingview.com/symbols/AMEX-$1 >> tmp #NYSE, NASDAQ, AMEX add up
cat tmp |egrep  -A 45 -B 1 "idea__label tv-idea-label--long|idea__label tv-idea-label--short" |egrep -o "idea-label--long|idea-label--short|data-username=\"\S+\"|data-timestamp=\"[0-9]+.[0-9]|idea__timeframe\">, [0-9DWM]+<" |sed -e 's/idea__timeframe">, //g' -e 's/idea-label--//g' -e 's/data-username="//g' -e 's/data-timestamp=\"//g' -e 's/<//g' -e 's/"//g' |tr '\n' ','|sed 's/\.0,/\n/g' |awk -F',' '{if (NF>3) print $1","$2","$3","$4}' > tmp1
[[ -s tmp1 ]] && echo "TradingviewUser LongShort YYYYMMDD TradeWindow Reputation #Ideas #Likes #Followers" |awk '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'; cat tmp1|while read post
do  
  timestamp=$(date -d @`echo $post|cut -d',' -f4` +%Y%m%d)  
  timestampSec=$(date --date "$timestamp" +'%s')   
  monthagoSec=$(date --date "30 days ago" +'%s')  
  if [ $timestampSec -gt $monthagoSec ]; then 
    timeframe=$(echo $post|cut -d',' -f1)
    longshort=$(echo $post|cut -d',' -f2)
    user=$(echo $post|cut -d',' -f3)
    profile=$($mycurl https://www.tradingview.com/u/$user/|egrep -B 1 'icon--reputation|icon--charts|icon--likes|icon--followers'|egrep "item-value"|cut -d'>' -f2|cut -d '<' -f1|tr '\n' ',')
    echo $user,$longshort,$timestamp,$timeframe,$profile |awk -F',' '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'
  fi  
done

#stocktwits.com
$mycurl https://api.stocktwits.com/api/2/streams/symbol/$1.json 2>&1 > tmp1 
cat tmp1 |jq '.messages[]|select(.entities.sentiment.basic=="Bullish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] && echo "Stockwits Bull Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp
cat tmp1 |jq '.messages[]|select(.entities.sentiment.basic=="Bearish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] && echo "Stockwits Bear Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp

$mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq '.experts[]|select (.ratings[].date>="'$(date -d "-30 days" "+%Y-%m-%d")'") |.ratings[0].url,.name,.rankings[0].stars,.rankings[0].avgReturn,.ratings[0].timestamp,.ratings[0].quote.title'|sed 's/"//g' |tr '\n' ';' |sed 's/http/\nhttp/g' |egrep -v '^$' > tmp
[[ -s tmp ]] && echo "Expert Name--------------Rating-Return%-YYYY-MM-DD-----URL---------------------------Title------------------"; cat tmp |while read line
do              #Tipranks Expert's Rating(0-5), Return%(per rating), tiny-url-to-access-article, Title/Abstract
   url=$(echo $line |cut -d';' -f1)
   tinyurl=$($mycurl -s "http://tinyurl.com/api-create.php?url=$url")
   echo $tinyurl";"$line | awk -F';' '{printf("%-27s%-5s%-8s%-15s%-30s%s\n",substr($3,0,25),$4,$5*100,substr($6,0,11),$1,$7)}'
done

#fool.com players' picks 
echo "Fool Player-------------------Rating--MM/DD/YYYY--Time--StartPrice--URL-----------------"
$mycurl "https://caps.fool.com/Ticker/$1/Scorecard.aspx" |egrep -A 27 "player/\w+" |egrep -A 2 "\w+.asp|numeric|date" |egrep -v '<td|td>|<a|a>|^\s+$|--' \
|sed 's/[[:space:]]//g'|tr '\n' ',' |sed -E -e 's/-[0-9]+\.[0-9]+%,/\n/g' -e 's/\+[0-9]+\.[0-9]+%,/\n/g' -e 's/&lt;/</g' |egrep -v "<del" |head -n 5   \
|awk -F',' '{printf("%-30s%-8s%-12s%-6s%-12shttps://caps.fool.com/player/%s.aspx\n",$1,$2,$3,$4,$5,$1)}' 

>tmp #Marketwatch games
egrep "^$1,"  $GAMES |while read line
do
  transactionDate=$(echo $line |cut -d',' -f2)
  transactionSec=$(date --date "$transactionDate" +'%s')   
  weekagoSec=$(date --date "7 days ago" +'%s')
  url="https://www.marketwatch.com/$(echo $line |cut -d',' -f5)"  
  tinyurl=$($mycurl -s "http://tinyurl.com/api-create.php?url=$url")  
  [ $transactionSec -gt $weekagoSec ] && echo $line,$tinyurl |awk -F',' '{printf "%-12s%-10s%-9s%-s\n",$3,$2,$4,$6}' >> tmp
done
[[ -s tmp ]] && echo "Buy/Short---Date------#Rank----MarketWatch Game---------------------------"; cat tmp

#Whale Wisdom
egrep "^$1," $WHALEWISDOM |sort | uniq |sed -e 's/whalewisdom-add.csv/Add/g' -e 's/whalewisdom-new.csv/New/g'> tmp
[[ -s tmp ]] && echo "Whales Recent 13F filer-----------------------------------------------LastQ---LastY--"; \
cat tmp  |awk -F',' '{printf("%-10s%-60s%-8s%-8s\n",$1,$2,$3,$4)}'

if  egrep -wq "$1" $ARK; then #Ark Investment daily change tracked by arktrack.com  
  echo "ARK :Buy(+)/Sell(-)/Hold(0) in last 30 trading days----------------------------------"
  for ark in ARKW ARKK ARKQ ARKG ARKF
  do #show 30 days add(+)/sell(-)/hold(0) position for last 30 trading days from left to right
    trend=$($mycurl 'https://www.arktrack.com/'$ark'.json' | jq -r '.[] | select(.ticker == "'$1'") |.shares' |tail -n 30 |tr '\n' ' ' \
      |awk '{for (i = 1; i < NF; i++){x=$(i+1)-$i; if (x>0) printf "+";if (x<0) printf "-";if (x == 0) printf "0";}; }') #'
    [[ ! -z $trend ]] && echo "$ark:"$trend
  done
fi

#SeekingAlpha Long ideas
$mycurl "https://seekingalpha.com/stock-ideas/long-ideas"  |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |egrep -w "$1$" | sed "s/$1/SeekingAlpha\tLong/g"

#Gurufocus Latest Buy
egrep -w $1 $GURUFOCUS |while read guru; do echo "GuruFocus Latest:"$guru; done

#Barron's Picks & Pans
$mycurl "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |egrep -w $1 |cut -d',' -f2 |while read barron; do echo "Barron's Picks:"$barron; done
