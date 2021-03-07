#!/bin/bash

shopt -s expand_aliases
alias mycurl='curl -s --max-time 10 -L -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" --ipv4 --http2 --compressed '
set -- $(echo $1 |tr [:lower:] [:upper:]) #reset ticker to upper case
[[ ! $FINNHUB_KEY ]]      && FINNHUB_KEY=$(mycurl $REPLIT_DB_URL/FINNHUB_KEY) #if running on repl.it, set KEY by: curl $REPLIT_DB_URL -d 'FINNHUB_KEY=[value]'
[[ ! $FINNHUB_KEY ]]      && { echo "FINNHUB_KEY NOT defined (neither by system variable nor in repl.it key-value store"; exit; }
[[ ! $ALPHAVANTAGE_KEY ]] && ALPHAVANTAGE_KEY=$(mycurl $REPLIT_DB_URL/ALPHAVANTAGE_KEY)
[[ ! $ALPHAVANTAGE_KEY ]] && { echo "ALPHAVANTAGE_KEY NOT defined (neither by system variable nor in repl.it key-value store"; exit; }

FOOL="foolrecentpick.csv"
#GAMES="marketwatchgames.csv"
WHALEWISDOM="whalewisdom*.csv"
ARK="ark.csv"
GURUFOCUS="gurufocus.csv"

pagedump=$(mycurl "https://www.finviz.com/quote.ashx?t=$1")
market=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<tr/\n/g' |egrep -o ">$1.+\[[A-Z]+\]"|cut -d'[' -f2 |cut -d']' -f1 |sed 's/NASD/NASDAQ/g')
[[ -z $market ]] && { echo "Not a NYSE and NASDAQ stock"; exit; }
newsdate=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<tr/\n/g' | egrep "news-link" |egrep -m 2 -o ">[A-Z][a-z][a-z]-[0-9][0-9]-[0-9][0-9]" |tail -n 1)
company=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o '<title>.+<' |cut -d'>' -f2- |cut -d'<' -f1 |sed 's/Stock Quote//g')
industry=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<\/tr>/\n/g' |egrep -o '\"center.+fullview-links.+tab-link\">.[^<]+' |egrep -o 'tab-link\">.[^<]+' |sed 's/<b>//g' |cut -d'>' -f2 |tr '\n' '>' |sed 's/>$//g')
echo $company">"$industry

price=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o 'Current stock price].+<b>[0-9.]+</b>' |cut -d'>' -f5- |cut -d'<' -f1)
updown=$(echo $pagedump |sed 's/^M/\n/g' |sed 's/<\/tr>/\n/g' |egrep -o "Change</td>.+" |cut -d'>' -f5- |cut -d'<' -f1)
echo "$"$price $updown `date +%x`

echo "Fundamentals--------------------------------"
for key in  'Market Cap' 'Sales' 'Income' 'P/E' 'Forward P/E' 'P/S' 'P/B' 'PEG' 'P/FCF' 'Current Ratio' 'Profit Margin' 'ROE' 'SMA20' 'SMA50' 'SMA200'  \
            'Target Price' 'Recom' 'Insider Own' 'Insider Trans' 'Inst Own' 'Inst Trans' 'Dividend %' 'Rel Volume' 'Earnings'
do	
  color=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o ">$key<.+" |cut -c1-120 |egrep -o 'is-red|is-green')  
  val=$(echo $pagedump |sed 's/^M/\n/g' |egrep -o ">$key<.+" |cut -c1-120 |egrep -o '>[0-9]+.[0-9]+<|>[0-9]+.[0-9]+B<|>[-0-9]+.[0-9]+M<|>[0-9]+.[0-9]+%<|[A-Z][a-z]+ [0-9]+|[0-9]+.[0-9]+%|>-<' |tail -n 1 |sed -e 's/>//g' -e 's/<//g' -e 's/-$//g')  
  [[ $color == 'is-red'   && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'  | awk  '{ print "\033[31m"$0"\033[0m";}'
  [[ $color == 'is-green' && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'  | awk  '{ print "\033[32m"$0"\033[0m";}'
  [[ -z $color            && $val ]] && echo "$key:$val" |awk -F':' '{printf("%-15s\t%-s\n"),$1,$2}'
done
>tmp
earningsuprise=$(mycurl https://www.benzinga.com/stock/$1/earnings |egrep -o "positive\">[0-9.]+%|negative\">[-0-9.]+%" |cut -d'>' -f2|awk '{print ($1>0)?"+":"-"}'|tr -d '\n')  #'
[[ $earningsuprise ]] && echo -e "Earn Surprise:\t"$earningsuprise >> tmp
consensusrevenue=$(mycurl -H 'X-Requested-With: XMLHttpRequest' "https://seekingalpha.com/symbol/$1/earnings/estimates_data?data_type=revenue&unit=earning_estimates" |jq  '[.annual[]| {fiscalYear: .fiscalYear, yoy: .yoy}|select (.fiscalYear>='$(date +%Y)')]|sort_by(.fiscalYear)[0:4]|.[]|.fiscalYear,(.yoy|tostring[0:6]+"%")' |tr '\n' ' ') 
[[ $consensusrevenue ]] && echo -e "Revenue Trend:\t"$consensusrevenue |sed -e 's/"//g' -e 's/%/%|/g' >> tmp
lastrating=$(mycurl https://www.benzinga.com/stock/$1/ratings |egrep -A 2 "Research Firm" |tail -n 1|cut -d'>' -f3,5,7,9,11 |sed 's/<\/td>/ /g' |cut -d'<' -f1)
[[ $lastrating ]] && echo -e "Last Rating:\t"$lastrating >> tmp
insider=$(mycurl "https://finviz.com/quote.ashx?t=$1"|sed 's/<tr/\n/g' |egrep -m 1 'center\">Sale<|center\">Buy<'  |egrep -o ">.[^<][^>]+</td>" |sed -e 's/<\/td>//g' -e 's/>//g' |cat -n |egrep '^\s+(2|3|4|5|7)' |cut -c8-|tr '\n' '|') #most recent buy/sale'
[[ $insider ]] && echo -e "Insider:\t\t"$insider >> tmp
etf=$(mycurl "https://etfdb.com/stock/$1/"|egrep Ticker|egrep Weighting|head -n 1 |egrep -o "href=\"/etf/[A-Z]+/\">[A-Z]+<|Weighting\">[0-9]+\.[0-9]+%"\
      |cut -d'>' -f2|sed 's/<//g' |tr '\n' ' ')
[[ $etf ]] && echo -e "ETF/Weight:\t\t"$etf #|awk '{printf("ETF/Weight\t\t%-s/%2.2f%%\n",$1,$2)}' >> tmp
cat tmp

echo "Valuations------------------------------------"
dcf=$(mycurl "https://www.gurufocus.com/stock/$1/dcf" |egrep -o ",iv_dcEarning:[0-9.]+|,iv_dcf:[0-9.]+" |cut -d':' -f2 |tr '\n' '/' |sed 's/\/$//g')
[[ $dcf ]] && echo -e "DCF(Earn/FCF):\t"$dcf

keystat=$(mycurl https://finance.yahoo.com/quote/$1/key-statistics)
evebitda=$(echo $keystat|sed -e 's/<tr/\n/g' -e 's/<\/tr/\n/g' |egrep -A 1 "Enterprise Value/EBITDA"  |egrep -o  'data-reactid="[0-9]+\">[-0-9.k]+</td' |head -n 1 |cut -d'>' -f2 |cut -d'<' -f1)
[[ $evebitda ]] && echo $evebitda |awk '{printf("EV/EBITDA:\t\t%3.2f\n",$1)}'

##ref:https://www.fool.com/investing/2019/09/25/introducing-the-rule-of-40-and-why-investors-shoul.aspx
rule40=$(mycurl "https://finnhub.io/api/v1/stock/metric?symbol=$1&metric=all&token=$FINNHUB_KEY" |jq ".metric.revenueGrowthTTMYoy,.metric.netProfitMarginAnnual" |egrep -v null |tr '\n' ' ')
[[ $rule40 ]] && echo $rule40 | awk '{if ($1+$2>40) print "Rule-40:\t\t\033[32m"$1+$2"%\033[0m"; else print "Rule-40:\t\t"$1+$2"%";}' 

gfvalue=$(mycurl https://www.gurufocus.com$(mycurl https://www.gurufocus.com/stock/$1/summary | egrep -o 'href=\"/term/gf_value/[^ ]+' |cut -d'"' -f2) |egrep -o '[0-9,.]+ \(As of Today')
echo $gfvalue |awk '{if ($1>0) print $1}' |awk '{if ($1<'$price') print "GuruFocus:\t\t$\033[31m"$1"\033[0m"; else print "GuruFocus:\t\t$\033[32m"$1"\033[0m";}' 

fairvalue=$(mycurl https://finance.yahoo.com/quote/$1  |egrep -o 'Fw\(b\) Fl\(end\)\-\-m Fz\(s\).+'|cut -c1-80 |cut -d'>' -f2 |cut -d'<' -f1) #'
[[ $fairvalue ]] && echo -e "Yahoo:\t\t\t"$fairvalue  #by Argus Research from Yahoo

swsurl=$(mycurl 'https://17iqhzwxzw-dsn.algolia.net/1/indexes/companies/query?x-algolia-agent=Algolia%20for%20JavaScript%20(4.4.0)%3B%20Browser%20(lite)&x-algolia-api-key=be7c37718f927d0137a88a11b69ae419&x-algolia-application-id=17IQHZWXZW' \
-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101 Firefox/78.0' \
-H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'content-type: application/x-www-form-urlencoded' \
-H 'Origin: https://simplywall.st' -H 'DNT: 1' -H 'Connection: keep-alive' \
--data-raw '{"query":"('$1')","highlightPostTag":" ","highlightPreTag":" ","restrictHighlightAndSnippetArrays":true}' \
|jq -r '.hits[]|select (.uniqueSymbol| (contains("NYSE") or contains("Nasdaq")) and endswith(":'$1'")) |.url')
swsfairvalue=$(mycurl "https://simplywall.st$swsurl" |egrep -o '\[\[fair value\]\] \(\$[0-9]+.[0-9]+\)' |cut -d'(' -f2 |cut -d')' -f1) #'
[[ $swsfairvalue ]] && echo -e "Simply WS:\t\t"$swsfairvalue

echo "Ratings-------------------------------------------"
pagedump=$(mycurl "https://www.gurufocus.com/stock/$1/summary" |egrep -A 2 '^Financial Strength|^Profitability Rank|^Valuation Rank'|egrep -v "</"|egrep -v "\-\-" |sed 's/Rank//g')
strength=$(echo $pagedump |egrep -o 'Strength [0-9]+/10')
[[ $strength ]] && echo $strength |awk '{printf("Strength:\t\t%s\n",$2)}'
profitability=$(echo $pagedump |egrep -o 'Profitability [0-9]+/10')
[[ $profitability ]] && echo $profitability |awk '{printf("Profitability:\t%s\n",$2)}'
valuation=$(echo $pagedump |egrep -o 'Valuation [0-9]+/10')
[[ $valuation ]] && echo $valuation |awk '{printf("Valuation:\t\t%s\n",$2)}'

dateratingprice=$(mycurl -d "symbol=$1" "https://madmoney.thestreet.com/07/index.cfm?page=lookup" |egrep -A 12  '>[0-9]+/[0-9]+/[0-9]+<' |egrep -o '[0-9]+/[0-9]+/[0-9]+|[0-9]+.gif|\$[0-9]+.[0-9]+|\$[0-9]+' |head -n 3 |sed 's/.gif//g' |tr '\n' ',') #Crammer's MadMoney comments
[[ $dateratingprice ]] && echo -e "Crammer:\t\t"$dateratingprice |sed -e 's/,1,/,Sell,/g' -e 's/,2,/,Negative,/g' -e 's/,3,/,Neural,/g' -e 's/,4,/,Postive,/g' -e 's/,5,/,Buy,/g'

zack=$(mycurl "https://www.zacks.com/stock/quote/$1" |egrep -m1 "rank_chip" |cut -d'<' -f1 |sed 's/ //g')
[[ $zack ]] && echo -e "Zack Rank:\t\t"$zack

stoxline=$(mycurl "http://m.stoxline.com/stock.php?symbol=$1" |grep -A 2 "Overall" |egrep "pics/[0-9]s.png" |egrep  -o '[0-9]s.png' |sed 's/s.png/ stars/g')
[[ $stoxline ]] && echo -e "Stoxline:\t\t"$stoxline

motelyfool=$(mycurl https://caps.fool.com/Ticker/$1.aspx |egrep "capsStarRating" |head -n 1 |egrep -o "[0-9] out of 5")
[[ $motelyfool ]] && echo -e "MotelyFool:\t\t"$motelyfool

#TipRanks Score, price target and ratings
latestrating=$(mycurl "https://www.tipranks.com/api/liveFeeds/GetLatestAnalystRatings/?top=300&includeRatingsPreview=buy,sell,hold"|jq -r '.analystsPreview[]|select (.stockTicker=="'$1'")|.rating') #'
[[ $latestrating ]] && echo -e "TR Latest:\t\t"$latestrating
mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq ".tipranksStockScore.score,.bloggerSentiment.bullish,.portfolioHoldingData.priceTarget, \
.portfolioHoldingData.analystConsensus.consensus,\
.portfolioHoldingData.analystConsensus.distribution.buy, \
.portfolioHoldingData.analystConsensus.distribution.hold, \
.portfolioHoldingData.analystConsensus.distribution.sell" |tr '\n' ','|sed 's/"//g' |\
awk -F',' '{printf("TR Score:\t\t%d Bullish:%d%% Sentiment:%s\nPriceTarget:\t$%4.2f|Buy|Hold|Sell:%d|%d|%d\n"),$1,$2,$4,$3,$5,$6,$7}'

#Glassdoor employee rating for company
companyname=$(mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq -r .companyFullName)
reviewurl=$(mycurl 'https://www.glassdoor.com/Reviews/company-reviews.htm?context=Review' --data-urlencode "sc.keyword=$companyname"  |egrep "untranslatedUrl" |cut -d':' -f2- |sed "s/'//g")  
if [[ ! -z $reviewurl ]]; then  
  #reviewurl=$(mycurl 'https://www.glassdoor.com/Reviews/company-reviews.htm?context=Review' --data-urlencode "sc.keyword=$companyname"  |egrep "untranslatedUrl" |cut -d':' -f2- |sed "s/'//g")  
  pagedump=$(mycurl $reviewurl |egrep -o 'ratingValue" : "[0-9].[0-9]"|percentage="[0-9]+" id="EmpStats_Recommend|percentage="[0-9]+" id="EmpStats_Approve' |sed -e 's/percentage="//g' -e 's/\" id=\"EmpStats_/ /g' -e 's/ratingValue\" : \"//g' -e 's/"/ Rating\(out of 5\)/g') #' 
  [[ $pagedump ]] && echo -e "Glassdoor:\t\t"$pagedump
fi

echo "Technical & Trend ----------------------------------"
candlestick=$(mycurl "https://www.stockta.com/cgi-bin/analysis.pl?symb=$1" |egrep 'Recent CandleStick Analysis' |egrep -o '>[A-Za-z ]*(Bullish|Bearish|Neutral)<' |sed -e 's/>//g' -e 's/<//g')  #'
[[ $candlestick ]] && echo -e "CandleStick:\t"$candlestick
barchart=$(mycurl "https://www.barchart.com/stocks/quotes/$1/"  |egrep -o 'buy-color">[A-Za-z ]+</a>' |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/^ \+//g')
[[ $barchart ]] && echo -e "BarChart:\t\t"$barchart
signalpattern=$(mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker=$1" |egrep 'MainContent_LastSignal\"|MainContent_LastPattern\"' |cut -d'>' -f2- |cut -d'<' -f1 |tr '\n' '|')
[[ $signalpattern  ]] && echo -e "USBull Signal:\t"$signalpattern

#ref: https://www.investopedia.com/terms/w/williamsr.asp, /m/macd.asp
willr=$(mycurl "https://www.alphavantage.co/query?function=WILLR&symbol=$1&interval=daily&time_period=10&apikey=$ALPHAVANTAGE_KEY" |jq -r "[[.[]][1][].WILLR]|first")
echo $willr |awk '{if ($1<-80.0) print "William %R:\t\tOverSold"; if ($1>-20.0) print "William %R:\t\tOverBought"}'
macdcross=$(mycurl "https://www.alphavantage.co/query?function=MACD&symbol=$1&interval=daily&series_type=open&apikey=$ALPHAVANTAGE_KEY"|jq -r "[[.[]][1][]|.MACD_Hist]|.[0,1]" |tr '\n' ' ')  
echo $macdcross |awk '{if($1>0 && $2<0) print "MACD:\t\t\tGolden Cross"; if($1<0 && $2>0) print "MACD:\t\t\tDeath Cross"}'
rsi=$(mycurl "https://www.alphavantage.co/query?function=RSI&symbol=$1&interval=weekly&time_period=10&series_type=open&apikey=$ALPHAVANTAGE_KEY"| jq -r '[[.[]][1][].RSI]|first')
[[ $rsi ]] && echo -e "RSI(10):\t\t"$rsi

shortinterest=$(mycurl https://www.highshortinterest.com/all/ |egrep -o "q?s=[A-Z\.]+" |cut -d'=' -f2 |egrep -i $1)
[[ $shortinterest ]] && echo -e "Short Interest:\tHigh"

for screen in ta_p_doubletop ta_p_doublebottom ta_p_multiplebottom ta_p_multipletop ta_p_channeldown ta_p_channelup ta_p_tlsupport ta_p_tlresistance ta_p_wedgeup ta_p_wedgedown \
              it_latestsales it_latestbuys n_earningsbefore n_earningsafter n_upgrades n_downgrades ta_oversold ta_overbought ta_unusualvolume ta_newlow ta_newhigh 
do
  mycurl "https://finviz.com/screener.ashx?v=410&s="$screen |egrep -o "quote.ashx\?t=[A-Z]+" |cut -d'=' -f2 |sort |uniq |egrep -w $1 |sed -e "s/$1/Screener:\t\t$screen/g" \
          -e 's/ta_p_//g' -e 's/it_//g' -e 's/n_//g' -e 's/ta_//g'
done

egrep -w $1 simplywallstreet.csv  |sed -e "s/$1/SimplyScreen:/g" -e "s/,/\t/g"

echo "News"$newsdate"==================================================================================================" #recent (~1-2 days) news to show "heat index"
[[ $newsdate ]] && mycurl "https://www.finviz.com/quote.ashx?t=$1" |egrep -B 20 $newsdate |egrep -o 'tab-link-news">.[^<]+' |cut -d'>' -f2-  |cat -n |sed 's/^[[:space:]]*//g'

echo "What people say(social media)===================================================================================="
>tmp
mycurl "https://www.tradingview.com/symbols/$market-$1"  |egrep  -A 45 -B 1 "idea__label tv-idea-label--long|idea__label tv-idea-label--short" |egrep -o "idea-label--long|idea-label--short|data-username=\"\S+\"|data-timestamp=\"[0-9]+.[0-9]|idea__timeframe\">, [0-9DWM]+<" |sed -e 's/idea__timeframe">, //g' -e 's/idea-label--//g' -e 's/data-username="//g' -e 's/data-timestamp=\"//g' -e 's/<//g' -e 's/"//g' |tr '\n' ','|sed 's/\.0,/\n/g' |awk -F',' '{if (NF>3) print $1","$2","$3","$4}' |while read post
do  
  timestamp=$(date -d @`echo $post|cut -d',' -f4` +%Y%m%d)  
  timestampSec=$(date --date "$timestamp" +'%s')   
  monthagoSec=$(date --date "30 days ago" +'%s')  
  if [ $timestampSec -gt $monthagoSec ]; then 
    timeframe=$(echo $post|cut -d',' -f1)
    longshort=$(echo $post|cut -d',' -f2)
    user=$(echo $post|cut -d',' -f3)
    profile=$(mycurl https://www.tradingview.com/u/$user/|egrep -B 1 'icon--reputation|icon--charts|icon--likes|icon--followers'|egrep "item-value"|cut -d'>' -f2|cut -d '<' -f1|tr '\n' ',')
    echo $user,$longshort,$timestamp,$timeframe,$profile |awk -F',' '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}' >> tmp
  fi  
done
[[ -s tmp ]] && echo "TradingviewUser LongShort YYYYMMDD TradeWindow Reputation #Ideas #Likes #Followers" |awk '{printf "%-30s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'; cat tmp

pagedump=$(mycurl https://api.stocktwits.com/api/2/streams/symbol/$1.json)
echo $pagedump |jq '.messages[]|select(.entities.sentiment.basic=="Bullish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]' 2>/dev/null\
  |tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] &&  echo "Stockwits Bull Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp; 
echo $pagedump |jq '.messages[]|select(.entities.sentiment.basic=="Bearish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]' 2>/dev/null \
  |tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}' > tmp
[[ -s tmp ]] &&  echo "Stockwits Bear Time--Investor--------------------#Ideas--#Followers--#Likes"; cat tmp; 

mycurl "https://www.tipranks.com/api/stocks/getData/?name=$1" |jq '.experts[]|select (.ratings[].date>="'$(date -d "-30 days" "+%Y-%m-%d")'") |.ratings[0].url,.name,.rankings[0].stars,.rankings[0].avgReturn,.ratings[0].timestamp,.ratings[0].quote.title'|sed 's/"//g' |tr '\n' ';' |sed 's/http/\nhttp/g' |egrep -v '^$' > tmp
[[ -s tmp ]] && echo "Expert Name--------------Rating-Return%-YYYY-MM-DD-----URL---------------------------Title------------------"
cat tmp |while read line
do #Tipranks Expert's Rating(0-5), Return%(per rating), tiny-url-to-access-article, Title/Abstract
   url=$(echo $line |cut -d';' -f1)
   tinyurl=$(mycurl  "http://tinyurl.com/api-create.php?url=$url")
   echo $tinyurl";"$line | awk -F';' '{printf("%-27s%-5s%-8s%-15s%-30s%s\n",substr($3,0,25),$4,$5*100,substr($6,0,11),$1,$7)}'
done

mycurl "https://www.youtube.com/results?search_query=$1+stock&sp=CAI%253D" |egrep -o 'title\":{\"runs\":\[{\"text\":\".[^}]+|[0-9] (minutes|hour|hours|day|days) ago|watch\?v=.[^"]+' |uniq |sed 's/title":{"runs":\[{"text":"//g' |tac |egrep -A 100 'watch\?v=' |tr '\n' ',' |sed -e 's/",/\n/g' -e 's/watch?v=//g' |tac |egrep " ago" |awk  '{print "https://youtu.be/"$0}' > tmp
[[ -s tmp ]] && echo "Youtubers---------------------------------------------------------------------------------------------------------"; cat tmp; 

utc7daysago=$(date --date="7 days ago" +%s)
>tmp
for subreddit in wallstreetbets stocks trakstocks SecurityAnalysis
do
  mycurl "https://www.reddit.com/r/"$subreddit"/search.json?q="$1"&restrict_sr=on&sort=new" | jq -r '.data.children[].data 
    |select(.created_utc>'$utc7daysago')  
    |select(.url | contains("comments"))  
    |select(.selftext|test (" '$1' "))|.url' >> tmp
done
[[ -s tmp ]] && echo "Redditers---------------------------------------------------------------------------------------------------------"; cat tmp; 

#SeekingAlpha Long ideas
#url=$(mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |egrep -o 'a-title\" href=\".[^"]+|\/symbol\/[A-Z]+' |sed "/symbol\/$1/q" |tac |egrep -m 1 "a-title" |cut -d'"' -f3)
long=$(mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |egrep "/symbol/$1")
if [[ $long ]]; then
  echo "SeekingAlpha-------------------------------------------------------------------------"
  url=$(mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |egrep -o 'a-title\" href=\".[^"]+|\/symbol\/[A-Z]+' |sed "/symbol\/$1/q" |tac |egrep -m 1 "a-title" |cut -d'"' -f3)
  tinyurl=$(mycurl "http://tinyurl.com/api-create.php?url="https://seekingalpha.com/"$url")
  articleid=$(echo $url |cut -d'/' -f3 |cut -d'-' -f1)  
  articlepage=$(mycurl "https://seekingalpha.com/api/v3/articles/$articleid?include=author%2Cauthor.authorResearch%2Cauthor.authorSponsorProgram%2Cco_authors%2CprimaryTickers%2CsecondaryTickers%2CotherTags%2Cpresentations%2Cpresentations.slides%2Csentiments%2CpromotedService")
  #echo "https://seekingalpha.com/api/v3/articles/$articleid?include=author%2Cauthor.authorResearch%2Cauthor.authorSponsorProgram%2Cco_authors%2CprimaryTickers%2CsecondaryTickers%2CotherTags%2Cpresentations%2Cpresentations.slides%2Csentiments%2CpromotedService"
  disclosure=$(echo $articlepage |jq -r ".data.attributes.disclosure" |egrep -o "<span>.+<\/span> "  |cut -d'>' -f2 |cut -d'<' -f1)
  title=$(echo $articlepage |jq -r ".data.attributes.title")
  echo -n $disclosure" "; echo $tinyurl
  echo $title;
  echo $articlepage |jq -r ".data.attributes.summary"
fi

#Barron's Picks & Pans
mycurl "https://www.barrons.com/picks-and-pans?page=1" |sed 's/<tr /\n/g' |awk '/<th>Symbol<\/th>/,/id="next"/'|egrep -o "barrons.com/quote/STOCK/[A-Z/]+|[0-9]+/[0-9]+/[0-9]+" |tr '\n' ',' |sed 's/barrons/\n/g' |cut -d '/' -f6- |egrep -w $1 |cut -d',' -f2 |while read barron
do echo "Barron's Picks:"$barron"------------------------------------------------------------"; done

#WallStreetBets mentioned in 24 hours (as a 'hot' index)
wsb_mentions=$(mycurl 'https://wsbsynth.com/ajax/get_table.php' | jq -r '.data_values |map(.symbol=="'$1'") |index(true)') #' 
[[ $wsb_mentions -ne "null" ]] && echo -e "WSB HotIndex:\t"$wsb_mentions

echo 
echo "What people do==================================================================================================="
#Fool players' portofolio
mycurl "https://caps.fool.com/Ticker/$1/Scorecard.aspx" |egrep -A 30 "player/\w+" |egrep -v "<del>|[[:space:]]+$" |egrep -A 2 "\w+.asp|numeric|date" \
  |egrep -v '<td|td>|<a|a>|^\s+$|--'|sed 's/[[:space:]]//g'|tr '\n' ',' |sed -E -e 's/-[0-9]+\.[0-9]+%,/\n/g' -e 's/\+[0-9]+\.[0-9]+%,/\n/g' -e 's/&lt;/</g'  |head -n 5 > tmp
[[ -s tmp ]] && echo "Fool Player-------------------Rating--MM/DD/YYYY--Time--StartPrice--URL---------------";
cat tmp |awk -F',' '{printf("%-30s%-8s%-12s%-6s%-12shttps://caps.fool.com/player/%s.aspx\n",$1,$2,$3,$4,$5,$1)}'

#>tmp #Marketwatch games
#weekagoSec=$(date --date "7 days ago" +'%s')
#egrep "^$1,"  $GAMES |while read line
#do
#  transactionDate=$(echo $line |cut -d',' -f2)
#  transactionSec=$(date --date "$transactionDate" +'%s')     
#  url="https://www.marketwatch.com/$(echo $line |cut -d',' -f5)"  
#  tinyurl=$(mycurl "http://tinyurl.com/api-create.php?url=$url")  
#  [ $transactionSec -gt $weekagoSec ] && echo $line,$tinyurl |awk -F',' '{printf "%-12s%-10s%-9s%-s\n",$3,$2,$4,$6}' >> tmp
#done
#[[ -s tmp ]] && echo "Buy/Short---Date------#Rank----Game---------------------------"; cat tmp; 

#Ark Investment daily change tracked by arktrack.com    
if  egrep -wq "$1" $ARK; then 
  echo "ARK :Significant(>1%) change(+/-/0) in the fund in last 30 days----------------------------"
  for ark in ARKW ARKK ARKQ ARKG ARKF
  do #show percent-change for last 30 trading days, the rightmost being the most recent change
    percent=$(mycurl 'https://www.arktrack.com/'$ark'.json' | jq -r '.[] |(.ticker|split(" ")[0]) as $short|select ($short == "'$1'")|.percent' |tail -n 1)
    trend=$(mycurl 'https://www.arktrack.com/'$ark'.json'   | jq -r '.[] |(.ticker|split(" ")[0]) as $short|select ($short == "'$1'")|.shares'  |tail -n 25 |tr '\n' ' '\
      |awk '{for(i=1;i<NF;i++) {x=($(i+1)-$i)/$i; if(x>0.01) printf "+"; if(x<-0.01) printf "-"; if(x<0.01 && x>-0.01) printf "0";} }') #' 
    [[ $percent ]] && echo "$ark:($percent%)"$trend
  done
fi

#WhaleWisdom ADD/NEW with performance records
egrep -w "^$1" $WHALEWISDOM |egrep '[0-9.]+%,[0-9.]+%' |awk -F',' '{print $4,$5,$2,$3}' |sort -nr |awk '{printf("%-60s%-16s%-8s%-8s\n",$4,$3,$1,$2)}' >tmp
[[ -s tmp ]] && echo "Recent 13F filers by whaleswisdom---------------------------Action----------LastQ---LastY---"; cat tmp  

#Gurufocus Latest Buy  #TODO: https://www.gurufocus.com/stock/<ticker>/guru-trades
mycurl "https://www.dataroma.com/m/activity.php?sym=$1&typ=a"  | tr -d $'\r' |cat -n > tmp 
last=$(cat tmp |egrep -o   '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |head -n 1 |sed -e 's/<b>//g' -e 's/<\/b> &nbsp/ /g')
head=$(cat tmp |egrep -m 2 '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |head -n 1 |awk '{print $1}')
tail=$(cat tmp |egrep -m 2 '<b>Q[0-9]</b> &nbsp<b>[0-9]+' |tail -n 1 |awk '{print $1}')
if [[ $last && $head && $tail ]]; then 
  echo "QQ-YYYY-13F filers by dataroma----------------------------------------Action----------"; 
  [[ $tail == $head ]] && tail=1000 
  cat tmp |sed -n "${head},${tail}p" |egrep -o '\"firm\">.+|class=\"buy\">[A-Z].+|class=\"sell\">[A-Z].+' |tr '\n' ',' |sed 's/"firm"/\n/g' |cut -d'>' -f3- |sed -e 's/<\/a>//g' -e 's/<\/td>//g' -e 's/class=\S*>//g' |egrep -v '^$' | while read buysell
  do
    echo $last","$buysell|awk -F',' '{printf("%-8s%-62s%-15s\n",$1,$2,$3)}'
  done
fi

onemonth=$(date -d'30 days ago' +%s) #investor (4.5+ stars) recent (<30 days) transaction  
mycurl "https://www.tipranks.com/api/crowd/publicPortfolios/?ticker=$1" |jq -r --arg onemonth "$onemonth" '.[] | select ((.effectiveDate+"Z" |fromdateiso8601 >'$onemonth') and (.stars>4.5)) |.expertPortfolioID,.stars,.portfolioActionID,.adjExecutionPrice, .effectiveDate' |tr '\n' ',' |sed 's/T00:00:00/\n/g' |sed -e 's/^,//g' -e 's/,1,/,opened,/g' -e 's/,2,/,increased,/g' -e 's/,3,/,reduced,/g' -e 's/,4,/,closed,/g' |awk -F',' '{printf ("%8s%8.2f%12s%8.2f%16s\n",$1,$2,$3,$4,$5)}' > tmp
[[ -s tmp ]] && echo "TipRankID  Stars      Action   Price      Date--------------------------------------------------------------------"; cat tmp; 