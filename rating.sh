#!/bin/bash

shopt -s expand_aliases
alias mycurl='curl -s --max-time 10 -L --ipv4 -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0"'

set -- $(echo $1 |tr [:lower:] [:upper:]) #reset ticker to upper case
FOOL="foolrecentpick.csv"
GAMES="marketwatchgames.csv"
WHALEWISDOM="whalewisdom*.csv"
ARK="ark.csv"
GURUFOCUS="gurufocus.csv"

pagedump=$(mycurl "https://www.finviz.com/quote.ashx?t=$1")
newsdate=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<tr/\n/g' | egrep "news-link" |egrep -m 2 -o ">[A-Z][a-z][a-z]-[0-9][0-9]-[0-9][0-9]" |tail -n 1)
market=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<tr/\n/g' |egrep -o ">$1.+\[[A-Z]+\]"|cut -d'[' -f2 |cut -d']' -f1 |sed 's/NASD/NASDAQ/g')
company=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o '<title>.+<' |cut -d'>' -f2- |cut -d'<' -f1 |sed 's/Stock Quote//g')
industry=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<\/tr>/\n/g' |egrep -o '\"center.+fullview-links.+tab-link\">.[^<]+' |egrep -o 'tab-link\">.[^<]+' |sed 's/<b>//g' |cut -d'>' -f2 |tr '\n' '>' |sed 's/>$//g')
echo $company">"$industry

price=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o 'Current stock price].+<b>[0-9.]+</b>' |cut -d'>' -f5- |cut -d'<' -f1)
updown=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<\/tr>/\n/g' |egrep -o "Change</td>.+" |cut -d'>' -f5- |cut -d'<' -f1)
echo "$"$price $updown `date +%x`

echo "Fundamentals--------------------------------"
for key in 'Market Cap' 'P/E' 'Forward P/E' 'P/S' 'PEG' 'P/FCF' 'Quick Ratio' 'Debt/Eq' 'ROE' 'SMA20' 'Target Price' 'Recom' \
            'Insider Own' 'Insider Trans' 'Inst Own' 'Inst Trans' 'Dividend %' 'Rel Volume' 'Earnings'
do	
  color=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o ">$key<.+" |cut -c1-120 |egrep -o 'is-red|is-green')  
  val=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o ">$key<.+" |cut -c1-120 |egrep -o '>[0-9]+.[0-9]+<|>[0-9]+.[0-9]+B<|>[0-9]+.[0-9]+M<|>[0-9]+.[0-9]+%<|[A-Z][a-z]+ [0-9]+|[0-9]+.[0-9]+%|>-<' |tail -n 1 |sed -e 's/>//g' -e 's/<//g' -e 's/-//g')  
  [[ $color == 'is-red'   && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'  | awk  '{ print "\033[31m"$0"\033[0m";}'
  [[ $color == 'is-green' && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'  | awk  '{ print "\033[32m"$0"\033[0m";}'
  [[ -z $color            && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'
done
earningsuprise=$(mycurl https://www.benzinga.com/stock/$1/earnings |egrep -o "positive\">[0-9.]+%|negative\">[-0-9.]+%" |cut -d'>' -f2|awk '{print ($1>0)?"+":"-"}'|tr -d '\n')  #'
[[ ! -z $earningsuprise ]] && echo -e "Earning Suprise\t"$earningsuprise 

lastrating=$(mycurl https://www.benzinga.com/stock/$1/ratings |egrep -A 2 "Research Firm" |tail -n 1|cut -d'>' -f3,5,7,9,11 |sed 's/<\/td>/ /g' |cut -d'<' -f1)
[[ ! -z $lastrating ]] && echo -e "Last Rating:\t"$lastrating

mycurl https://finviz.com/insidertrading.ashx |sed 's/tr/\n/g' |egrep -w "t=$1" |egrep -o ">Buy<|>Sale<|>Option Exercise<" |sed -e 's/>//g' -e 's/<//g' |while read buysell
do
  echo -e "Insider:\t\t$buysell"
done

etf=$(mycurl "https://etfdb.com/stock/$1/"|egrep Ticker|egrep Weighting|head -n 1 |egrep -o "href=\"/etf/[A-Z]+/\">[A-Z]+<|Weighting\">[0-9]+\.[0-9]+%"\
      |cut -d'>' -f2|sed 's/<//g' |tr '\n' ' ')
[[ ! -z $etf ]] && echo $etf |awk '{printf("ETF/Weight\t\t%-s/%2.2f%%\n",$1,$2)}' 

echo "Valuations------------------------------------"
dcf=$(mycurl "https://www.gurufocus.com/dcf/$1" |egrep "var data = \[" |egrep -o "y:[-0-9.]+[^{]+/term/\w+/" |cut -d':' -f2,4 |sed "s/,color:'\/term//g" |cut -d'/' -f2,1 \
      |egrep iv_dc |sort -nr |sed -e 's/iv_dcf_share/(Projectd-FCF-based)/g' -e 's/\/iv_dcf/(FCF-based)/g' -e 's/\/iv_dcEarning/(Earning-based)/g' |head -n 1) #'
[[ ! -z $dcf ]] && echo $dcf |awk '{printf("Max DCF:\t\t%s\n",$1)}'

keystat=$(mycurl https://finance.yahoo.com/quote/$1/key-statistics)
evebitda=$(echo $keystat|sed -e 's/<tr/\n/g' -e 's/<\/tr/\n/g' |egrep -A 1 "Enterprise Value/EBITDA"  |egrep -o  'data-reactid="[0-9]+\">[-0-9.k]+</td' |head -n 1 |cut -d'>' -f2 |cut -d'<' -f1)
[[ ! -z $evebitda ]] && echo $evebitda |awk '{printf("EV/EBITDA:\t\t%3.2f\n",$1)}'

##ref:https://www.fool.com/investing/2019/09/25/introducing-the-rule-of-40-and-why-investors-shoul.aspx
rule40=$(mycurl "https://www.google.com/finance/quote/$1:$market" |sed 's/<td/\n/g'|egrep -A 2 "Revenue|Net profit margin"|egrep -o ">arrow.+%<"|cut -d'>' -f3-|cut -d'<' -f1 |tr '\n' ' ')
[[ ! -z $rule40 ]] && echo $rule40 |awk '{printf("Rule-of-40%%:\t%3.2f%%\n",$1+$2)}'


gfvalue=$(mycurl https://www.gurufocus.com$(mycurl https://www.gurufocus.com/stock/$1/summary | egrep -o 'href=\"/term/gf_value/[^ ]+' |cut -d'"' -f2) |egrep -o '[0-9.]+ \(As of Today')
[[ ! -z $gfvalue   ]] && echo $gfvalue |awk '{if ($1<'$price') print "GuruFocus:\t\t$\033[31m"$1"\033[0m"; else print "GuruFocus:\t\t$\033[32m"$1"\033[0m";}' 

fairvalue=$(mycurl https://finance.yahoo.com/quote/$1  |egrep -o 'Fw\(b\) Fl\(end\)\-\-m Fz\(s\).+'|cut -c1-80 |cut -d'>' -f2 |cut -d'<' -f1) #'
[[ ! -z $fairvalue ]] && echo -e "Yahoo:\t\t\t"$fairvalue  #by Argus Research from Yahoo

echo "Ratings-------------------------------------------"
mycurl "https://www.gurufocus.com/stock/$1/summary" |egrep -A 2 '^Financial Strength|^Profitability Rank|^Valuation Rank' |egrep -v "^</" |tr '\n' ' ' |sed -e 's/--/\n/g' -e 's/Financial//g' -e 's/Rank//g' |awk '{if (NF==2) printf("%-16s%-5s\n",$1":",$2)}'

dateratingprice=$(mycurl -d "symbol=$1" "https://madmoney.thestreet.com/07/index.cfm?page=lookup" |egrep -A 12  '>[0-9]+/[0-9]+/[0-9]+<' |egrep -o '[0-9]+/[0-9]+/[0-9]+|[0-9]+.gif|\$[0-9]+.[0-9]+|\$[0-9]+' |head -n 3 |sed 's/.gif//g' |tr '\n' ',') #Crammer's MadMoney comments
[[ ! -z $dateratingprice ]] && echo -e "Crammer:\t\t"$dateratingprice |sed -e 's/,1,/,Sell,/g' -e 's/,2,/,Negative,/g' -e 's/,3,/,Neural,/g' -e 's/,4,/,Postive,/g' -e 's/,5,/,Buy,/g'

zack=$(mycurl "https://www.zacks.com/stock/quote/$1" |egrep -m1 "rank_chip" |cut -d'<' -f1 |sed 's/ //g')
[[ ! -z $zack ]] && echo -e "Zack Rank:\t\t"$zack

stoxline=$(mycurl "http://m.stoxline.com/stock.php?symbol=$1" |grep -A 2 "Overall" |egrep "pics/[0-9]s.png" |egrep  -o '[0-9]s.png' |sed 's/s.png/ stars/g')
[[ ! -z $stoxline ]] && echo -e "Stoxline:\t\t"$stoxline

motelyfool=$(mycurl https://caps.fool.com/Ticker/$1.aspx |egrep "capsStarRating" |head -n 1 |egrep -o "[0-9] out of 5")
[[ ! -z $motelyfool ]] && echo -e "MotelyFool:\t\t"$motelyfool

#TipRanks Score, price target and ratings
mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq ".tipranksStockScore.score,.bloggerSentiment.bullish,.portfolioHoldingData.priceTarget, \
.portfolioHoldingData.analystConsensus.consensus,\
.portfolioHoldingData.analystConsensus.distribution.buy, \
.portfolioHoldingData.analystConsensus.distribution.hold, \
.portfolioHoldingData.analystConsensus.distribution.sell" |tr '\n' ','|sed 's/"//g' |\
awk -F',' '{printf("TR Score:\t\t%d Bullish:%d%% Sentiment:%s\nPriceTarget:\t$%4.2f|Buy|Hold|Sell:%d|%d|%d\n"),$1,$2,$4,$3,$5,$6,$7}'

echo "Techincal & Trend ----------------------------------"
mycurl "https://www.stockta.com/cgi-bin/analysis.pl?symb="$1"&cobrand=&mode=stock" > tmp
trendspotter=$(cat tmp |grep -i 'class="analysisTd' |grep -v Intermediate |egrep -o '>[A-Za-z]+ \([-0-9.]+\)' |tr '>' '|' |head -n 1 |cut -d'|' -f2)  #'
candlestick=$(cat tmp  |egrep -A 2 CandleStick |egrep -o 'Recent CandleStick Analysis.+>[A-Za-z ]+|>Candle<.+borderTd">[A-Za-z ]+' |rev |cut -d'>' -f1 |rev |tr '\n' ' ')
[[ ! -z $trendspotter ]] && echo -e "Overall Trend:\t"$trendspotter
[[ ! -z $candlestick ]] && echo -e "Candle Stick:\t"$candlestick

barchart=$(mycurl "https://www.barchart.com/stocks/quotes/$1/"  |egrep -o 'buy-color">[A-Za-z ]+</a>' |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/^ \+//g')
[[ ! -z $barchart ]] && echo -e "Chart Signal:\t"$barchart

#TA patterns
signal=$(mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastSignal"  |egrep -o ">[A-Z ]+</font>" |cut -d'<' -f1|cut -d'>' -f2)
pattern=$(mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastPattern" |cut -d'>' -f3 |cut -d'<' -f1  |sed 's/NO PATTERN//g' |tr -d '\r\n')
[[ ! -z $single  ]] && echo -e "USBull Signal\t"$signal
[[ ! -z $pattern ]] && echo -e "USBull Pattern\t"$pattern
pretiming=$(mycurl "https://www.pretiming.com/search?q=$1" |egrep -A 5  -m1 "Recommended Positions"  |tail -n 1 |egrep -o -i "long-bullish|long-bearish|short-bullish|short-bearish")
[[ ! -z $pretiming ]] && echo -e "PreTiming TA:\t"$pretiming
oversold=$(mycurl "https://www.tradingview.com/markets/stocks-usa/market-movers-oversold"|egrep "window.initData.screener_data" |egrep -o "NYSE:[A-Z]+|NASDAQ:[A-Z]+|AMEX:[A-Z]+"|egrep -w $1)
[[ ! -z $oversold ]] && echo -e "TradingView:\tOversold"
shortinterest=$(mycurl https://www.highshortinterest.com/all/ |egrep -o "q?s=[A-Z\.]+" |cut -d'=' -f2 |egrep -i $1)
[[ ! -z $shortinterest ]] && echo -e "Short Interest:\tHigh"

echo "News"$newsdate"==================================================================================================" #recent (~1-2 days) news to show "heat index"
mycurl "https://www.finviz.com/quote.ashx?t=$1" |egrep -B 20 $newsdate |egrep -o 'tab-link-news">.[^<]+' |cut -d'>' -f2-  |cat -n |sed 's/^[[:space:]]*//g'

echo "What people say==================================================================================================="
mycurl "https://www.tradingview.com/symbols/$market-$1" > tmp #ticker on NYSE, NASDAQ, AMEX separately
cat tmp  |egrep  -A 45 -B 1 "idea__label tv-idea-label--long|idea__label tv-idea-label--short" |egrep -o "idea-label--long|idea-label--short|data-username=\"\S+\"|data-timestamp=\"[0-9]+.[0-9]|idea__timeframe\">, [0-9DWM]+<" |sed -e 's/idea__timeframe">, //g' -e 's/idea-label--//g' -e 's/data-username="//g' -e 's/data-timestamp=\"//g' -e 's/<//g' -e 's/"//g' |tr '\n' ','|sed 's/\.0,/\n/g' |awk -F',' '{if (NF>3) print $1","$2","$3","$4}' > tmp
[[ -s tmp ]] && echo "TradingviewUser LongShort YYYYMMDD TradeWindow Reputation #Ideas #Likes #Followers" |awk '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'; cat tmp|while read post
do  
  timestamp=$(date -d @`echo $post|cut -d',' -f4` +%Y%m%d)  
  timestampSec=$(date --date "$timestamp" +'%s')   
  monthagoSec=$(date --date "30 days ago" +'%s')  
  if [ $timestampSec -gt $monthagoSec ]; then 
    timeframe=$(echo $post|cut -d',' -f1)
    longshort=$(echo $post|cut -d',' -f2)
    user=$(echo $post|cut -d',' -f3)
    profile=$(mycurl https://www.tradingview.com/u/$user/|egrep -B 1 'icon--reputation|icon--charts|icon--likes|icon--followers'|egrep "item-value"|cut -d'>' -f2|cut -d '<' -f1|tr '\n' ',')
    echo $user,$longshort,$timestamp,$timeframe,$profile |awk -F',' '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'
  fi  
done

mycurl https://api.stocktwits.com/api/2/streams/symbol/$1.json 2>&1 > tmp1 
cat tmp1 |jq '.messages[]|select(.entities.sentiment.basic=="Bullish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] && echo "Stockwits Bull Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp
cat tmp1 |jq '.messages[]|select(.entities.sentiment.basic=="Bearish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] && echo "Stockwits Bear Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp

mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq '.experts[]|select (.ratings[].date>="'$(date -d "-30 days" "+%Y-%m-%d")'") |.ratings[0].url,.name,.rankings[0].stars,.rankings[0].avgReturn,.ratings[0].timestamp,.ratings[0].quote.title'|sed 's/"//g' |tr '\n' ';' |sed 's/http/\nhttp/g' |egrep -v '^$' > tmp
[[ -s tmp ]] && echo "Expert Name--------------Rating-Return%-YYYY-MM-DD-----URL---------------------------Title------------------"; cat tmp |while read line
do              #Tipranks Expert's Rating(0-5), Return%(per rating), tiny-url-to-access-article, Title/Abstract
   url=$(echo $line |cut -d';' -f1)
   tinyurl=$(mycurl  "http://tinyurl.com/api-create.php?url=$url")
   echo $tinyurl";"$line | awk -F';' '{printf("%-27s%-5s%-8s%-15s%-30s%s\n",substr($3,0,25),$4,$5*100,substr($6,0,11),$1,$7)}'
done

#SeekingAlpha Long ideas
mycurl "https://seekingalpha.com/stock-ideas/long-ideas"|grep bull|egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+" |cut -d'/' -f3 |egrep -w "$1$"|sed "s/$1/SeekingAlpha-------------Long------/g"

#Barron's Picks & Pans
mycurl "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |egrep -w $1 |cut -d',' -f2 |while read barron; do echo "Barron's Picks--------------"$barron"------"; done

echo "What people do==================================================================================================="
echo "Fool Player-------------------Rating--MM/DD/YYYY--Time--StartPrice--URL---------------"
#mycurl "https://caps.fool.com/Ticker/$1/Scorecard.aspx" |egrep -A 27 "player/\w+" |egrep -v '<del>' |egrep -A 2 "\w+.asp|numeric|date" |egrep -v '<td|td>|<a|a>|^\s+$|--' \
#|sed 's/[[:space:]]//g'|tr '\n' ',' |sed -E -e 's/-[0-9]+\.[0-9]+%,/\n/g' -e 's/\+[0-9]+\.[0-9]+%,/\n/g' -e 's/&lt;/</g' |head -n 5   \
mycurl "https://caps.fool.com/Ticker/$1/Scorecard.aspx" |egrep -A 30 "player/\w+" |egrep -v "<del>|[[:space:]]+$" |egrep -A 2 "\w+.asp|numeric|date" \
|egrep -v '<td|td>|<a|a>|^\s+$|--'|sed 's/[[:space:]]//g'|tr '\n' ',' |sed -E -e 's/-[0-9]+\.[0-9]+%,/\n/g' -e 's/\+[0-9]+\.[0-9]+%,/\n/g' -e 's/&lt;/</g'  |head -n 5 \
|awk -F',' '{printf("%-30s%-8s%-12s%-6s%-12shttps://caps.fool.com/player/%s.aspx\n",$1,$2,$3,$4,$5,$1)}' 

>tmp #Marketwatch games
egrep "^$1,"  $GAMES |while read line
do
  transactionDate=$(echo $line |cut -d',' -f2)
  transactionSec=$(date --date "$transactionDate" +'%s')   
  weekagoSec=$(date --date "7 days ago" +'%s')
  url="https://www.marketwatch.com/$(echo $line |cut -d',' -f5)"  
  tinyurl=$(mycurl "http://tinyurl.com/api-create.php?url=$url")  
  [ $transactionSec -gt $weekagoSec ] && echo $line,$tinyurl |awk -F',' '{printf "%-12s%-10s%-9s%-s\n",$3,$2,$4,$6}' >> tmp
done
[[ -s tmp ]] && echo "Buy/Short---Date------#Rank----MarketWatch Game---------------------------"; cat tmp

if  egrep -wq "$1" $ARK; then #Ark Investment daily change tracked by arktrack.com  
  echo "ARK :Buy(+)/Sell(-)/Hold(0) in last 30 trading days----------------------------------"
  for ark in ARKW ARKK ARKQ ARKG ARKF
  do #show 30 days add(+)/sell(-)/hold(0) position for last 30 trading days from left to right
    trend=$(mycurl 'https://www.arktrack.com/'$ark'.json' | jq -r '.[] | (.ticker|split(" ")[0]) as $short|select ($short == "'$1'") |.shares' | tail -n 30 |tr '\n' ' ' \
      |awk '{for (i = 1; i < NF; i++){x=$(i+1)-$i; if (x>0) printf "+";if (x<0) printf "-";if (x == 0) printf "0";}; }') #'
    [[ ! -z $trend ]] && echo "$ark:"$trend
  done
fi

#Whale Wisdom
egrep "^$1," $WHALEWISDOM |sort | uniq |sed -e 's/whalewisdom-add.csv/Add/g' -e 's/whalewisdom-new.csv/New/g'> tmp
[[ -s tmp ]] && echo "Recent 13F filers by whaleswisdom-------------------------------------LastQ---LastY---"; \
cat tmp  |awk -F',' '{printf("%-10s%-60s%-8s%-8s\n",$1,$2,$3,$4)}'

#Gurufocus Latest Buy  #TODO: https://www.gurufocus.com/stock/<ticker>/guru-trades
mycurl "https://www.dataroma.com/m/activity.php?sym=$1&typ=a"  | tr -d $'\r' |cat -n > tmp 
last=$(cat tmp |egrep -o   '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |head -n 1 |sed -e 's/<b>//g' -e 's/<\/b> &nbsp/ /g')
head=$(cat tmp |egrep -m 2 '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |head -n 1 |awk '{print $1}')
tail=$(cat tmp |egrep -m 2 '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |tail -n 1 |awk '{print $1}')
if [[ ! -z $last && ! -z $head && ! -z $tail ]]; then 
  echo "QQ-YYYY-13F filers by dataroma----------------------------------------Action----------"; 
  [[ $tail == $head ]] && tail=1000 
  cat tmp |sed -n "${head},${tail}p" |egrep -o '\"firm\">.+|class=\"buy\">[A-Z].+|class=\"sell\">[A-Z].+' |tr '\n' ',' |sed 's/"firm"/\n/g' |cut -d'>' -f3- |sed -e 's/<\/a>//g' -e 's/<\/td>//g' -e 's/class=\S*>//g' |egrep -v '^$' | while read buysell
  do
    echo $last","$buysell|awk -F',' '{printf("%-8s%-62s%-15s\n",$1,$2,$3)}'
  done
fi
