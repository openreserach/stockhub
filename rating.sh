#!/bin/bash

mycurl="curl -s --max-time 3 -L -k --http2 -A 'Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0'"
mychrome="google-chrome-stable --headless --disable-gpu --dump-dom" #headless browser to deal with more javascript

$mycurl "https://www.finviz.com/quote.ashx?t=$1" > tmp
cat tmp|grep "<title>" |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/Stock Quote//g'
cat tmp|grep center |grep fullview-links |grep tab-link |cut -d'>' -f4,6,8 |sed 's/<\/a/ /g'

price=$(cat tmp|grep "Current stock price" |cut -d'>' -f5- |cut -d'<' -f1)
updown=$(cat tmp |egrep 'Change</td>' |egrep -o "color.+"|cut -d'>' -f2 |cut -d'<' -f1)
echo "$"$price $updown `date +%x`
echo "FA color-coded=============================="
for key in 'Market Cap' 'P/E' 'Forward P/E' 'P/C' 'P/FCF' 'P/B' 'Debt/Eq' 'Current Ratio' 'ROA' 'ROE' 'EPS next 5Y' 'Dividend %'
do
	color=`cat tmp |grep ">$key<" |egrep -o "color:#[0-9a]+" |cut -d':' -f2`
	val=`cat tmp |grep ">$key<" |egrep -o ">[0-9]+.[0-9]+<|>[0-9]+.[0-9]+B<|>[0-9]+.[0-9]+M<|>[0-9]+.[0-9]+%<" |sed -e 's/>//g' -e 's/<//g'`
	if [ "$color" == '#aa0000' ]; then 
		echo -e "$key:\t\t\e[00;31m$val\e[00m" 
	elif [ "$color" == '#008800' ]; then 
		echo -e "$key:\t\t\e[00;32m$val\e[00m" 
	else 
		echo -e "$key:\t\t$val"
    fi
done
echo "News=================================="
cat tmp |egrep "white-space:nowrap" |head -n 3 |egrep -o 'white-space:nowrap">\S+.+tab-link-news">.+</a>' |cut -d'>' -f2,5  |cut -c1-10,35- |cut -d'<' -f1
$mycurl "https://seekingalpha.com/symbol/"$1 |egrep -o 'class="symbol_latest_articles".+' |egrep -o '/news/.+' |egrep -o 'latest">.+' |cut -d'<' -f1 |cut -d'>' -f2

echo "Rating================================"
export sp500avgpe=`$mycurl https://www.multpl.com/ |egrep -o "Current S&P 500 PE Ratio is [0-9.]+" |rev |awk '{print $1}' |rev`
echo -e "S&P500 PE:\t"$sp500avgpe
export feargreed=`$mycurl https://money.cnn.com/data/fear-and-greed/ |egrep -o "Fear.+Greed Now: [0-9]+ \(\w+\)" |cut -d':' -f2`
echo -e "Fear-Greed:\t"$feargreed
#gurufocus Financial Strength & Profitability Strength
export FinancialStrength=$($mycurl https://www.gurufocus.com/stock/$1/summary |egrep -A 2 'Financial Strength' |egrep -A 1 fc-regular  |tail -n 1)
[[ ! -z $FinancialStrength ]] && echo -e "FinStrength:\t"$FinancialStrength
export Profitability=$($mycurl https://www.gurufocus.com/stock/$1/summary |egrep -A 2 'Profitability Rank' |egrep -A 1 fc-regular  |tail -n 1)
[[ ! -z $Profitability ]] && echo -e "Profitability:\t"$Profitability

#Crammer's MadMoney comments
export madmoneyurl="https://madmoney.thestreet.com/07/index.cfm?page=lookup"
export madmoneylookup="symbol=$1"
export dateratingprice=$($mycurl -s -d $madmoneylookup $madmoneyurl |egrep -A 12  '>[0-9]+/[0-9]+/[0-9]+<' |egrep -o '[0-9]+/[0-9]+/[0-9]+|[0-9]+.gif|\$[0-9]+.[0-9]+' |head -n 3 |sed 's/.gif//g' |tr '\n' ',')
[[ ! -z $dateratingprice ]] && echo -e "Crammer:\t"$dateratingprice"#0:Sell.. 5:Buy"
#$mycurl -d $madmoneylookup $madmoneyurl |tac |tac |egrep -m 1  ">[0-9]{2}/[0-9]{2}/200?" -A 20 >tmp #care the latest one
#export maddate=`cat tmp |egrep -o "[0-9]{2}/[0-9]{2}/20[0-9][0-9]"`
#export madbuysell=`cat tmp |egrep -o "[1-5]\.gif"|sed 's/.gif//g' |sed 's/5/SB/g'|sed 's/4/B/g'|sed 's/3/H/g'|sed 's/2/S/g'| sed 's/1/SS/g'`
#export madvalue=`cat tmp |egrep -o "[0-9]+\.[0-9]+"|head -n 1`
#export madchange=`cat tmp |egrep -o "\+ [0-9]+\.[0-9]+%|\- [0-9]+\.[0-9]+%"|tail -n 1`
#echo -e "Crammer:\t"$maddate $madbuysell $madvalue $madchange

export zack=`$mycurl "https://www.zacks.com/stock/quote/$1" |egrep -m1 "rank_chip" |cut -d'<' -f1 |sed 's/ //g'`
[[ ! -z $zack ]] && echo -e "Zack Rank:\t"$zack
#stoxline rating
export stoxline=`$mycurl "http://m.stoxline.com/stock.php?symbol=$1" |grep -A 2 "Overall" |egrep "pics/[0-9]s.png" |egrep  -o '[0-9]s.png' |sed 's/s.png/ stars/g'`
[[ ! -z $stoxline ]] && echo -e "Stoxline:\t"$stoxline

#Argus Research from Yahoo
$mychrome "https://finance.yahoo.com/quote/$1" > tmp 2>&1
fairvalue=`cat tmp |egrep -o 'Fw\(b\) Fl\(end\)\-\-m Fz\(s\).+'|cut -c1-80 |cut -d'>' -f2 |cut -d'<' -f1`
[[ ! -z $recommendation ]] && echo -e "Argus Research:\t"$recommendation
[[ ! -z $fairvalue      ]] && echo -e "Fair Value:\t"$fairvalue

#tipranks
tiprank=$($mycurl "https://www.tipranks.com/api/stocks/getNewsSentiments/?ticker="$1 |jq '.counts[0]'|egrep "buy|neutral|sell" |sort |awk '{print $2}'|sed 's/,//g' |tr '\n' ',' |awk -F',' '{printf "buy:%d neutral:%d sell:%d\n",$1,$2,$3}') 
echo -e "TipRank:\t"$tiprank

#MotleyFool's rating to be replace motley api
if [ ${FOOL_API_KEY} ] 
then  #apply for your own free key at http://developer.fool.com/, and set it in environment variable FOOL_API_KEY
	export star=`$mycurl "http://www.fool.com/a/caps/ws/Ticker/$1?apikey=$FOOL_API_KEY" |egrep -o 'Percentile="[0-5]"' |egrep -o "[0-5]"`
	echo -e "MotelyFool:\t"$star" out of 5"
fi
$mycurl "https://x-uni.com/api/screener-gd.php?param=1;5;10;3;20;10" |sed 's/,"/\n/g' |egrep -o -w $1 |sed "s/$1/Graham-Dodd-Value/g"
$mycurl "https://x-uni.com/api/screener-gf.php?params=2;;4.6"        |sed 's/,"/\n/g' |egrep -o -w $1 |sed "s/$1/Graham-Formula-Value/g"
$mycurl "https://seekingalpha.com/stock-ideas/long-ideas"  |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |tr [:lower:]  [:upper:]|egrep -w "$1$" | sed "s/$1/SeekingAlpha\tLong/g"

echo "TA & Trend ==================================="
$mycurl "https://www.stockta.com/cgi-bin/analysis.pl?symb="$1"&cobrand=&mode=stock" > tmp
trendspotter=`cat tmp |grep -i 'class="analysisTd' |grep -v Intermediate |egrep -o ">[A-Za-z]+ \([-0-9.]+\)" |tr '>' '|' |head -n 1 |cut -d'|' -f2`
candlestick=`cat tmp |egrep -A 2 CandleStick |egrep -o 'Recent CandleStick Analysis.+>[A-Za-z ]+|>Candle<.+borderTd">[A-Za-z ]+' |rev |cut -d'>' -f1 |rev |tr '\n' ' '`
[[ ! -z $trendspotter ]] && echo -e "Overall Trend:\t"$trendspotter
[[ ! -z $candlestick ]] && echo -e "Candle Stick:\t"$candlestick

export barchart=$($mycurl "https://www.barchart.com/stocks/quotes/$1/"  |egrep -o 'buy-color">[A-Za-z ]+</a>' |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/^ \+//g')
[[ ! -z $barchart ]] && echo -e "Barchart:\t"$barchart

#TA pattern
export signal= $($mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastSignal"  |egrep -o ">[A-Z ]+</font>" |cut -d'<' -f1|cut -d'>' -f2)
export pattern=$($mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker="$1 |egrep "MainContent_LastPattern" |cut -d'>' -f3 |cut -d'<' -f1  |sed 's/NO PATTERN//g' |tr -d '\r\n')
[[ ! -z $single  ]] && echo -e "USBull Signal\t"$signal
[[ ! -z $pattern ]] && echo -e "USBull Pattern\t"$pattern

pretiming=`$mycurl "https://www.pretiming.com/search?q=$1" |egrep -A 5  -m1 "Recommended Positions"  |tail -n 1 |egrep -o -i "long-bullish|long-bearish|short-bullish|short-bearish"`
[[ ! -z $pretiming ]] && echo -e "PreTiming TA:\t"$pretiming

oversold=`$mycurl "https://www.tradingview.com/markets/stocks-usa/market-movers-oversold" |egrep -o 'data-symbol="NASDAQ:[A-Z]+|data-symbol="NYSE:[A-Z]+' |cut -d':' -f2 |egrep -w $1`
[[ ! -z $oversold ]] && echo -e "TradingView:\tOversold"

echo "Radar Screen================================="
#Trading view
$mycurl https://www.tradingview.com/symbols/NYSE-$1 > tmp
$mycurl https://www.tradingview.com/symbols/NASDAQ-$1 >> tmp 
$mycurl https://www.tradingview.com/symbols/AMEX-$1 >> tmp #NYSE, NASDAQ, AMEX add up
echo "TradingviewUser LongShort YYYYMMDD TradeWindow Reputation #Ideas #Likes #Followers" | awk '{printf "%-25s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'
cat tmp |egrep -A 40 -B 1 'tv-widget-idea__label tv-idea-label--[a-z]+' |egrep -o 'tv-idea-label--[a-z]+|href=\"/u/[A-Za-z0-9\_\.\-]+/|idea__timeframe">.+<|data-timestamp="[0-9.]+"' |sed -e 's/idea__timeframe">, \+//g' -e 's/tv-idea-label--//g' -e 's/href="\/u\//,/g' -e 's/data-timestamp="//g' |tr -d '\n'| sed  -e 's/</,/g'  -e 's/"/\n/g' -e 's/\//,/g' |while read post
do
    timeframe=$(echo $post|cut -d',' -f1)
    longshort=$(echo $post|cut -d',' -f2)
    user=$(echo $post|cut -d',' -f3)
    timestamp=$(date -d @`echo $post|cut -d',' -f4` +%Y%m%d)
    profile=$($mycurl https://www.tradingview.com/u/$user/ |egrep -B 1 'icon--reputation|icon--charts|icon--likes|icon--followers' |egrep "item-value" |cut -d'>' -f2 |cut -d '<' -f1 |tr '\n' ',') 
    echo $user,$longshort,$timestamp,$timeframe,$profile |awk -F',' '{printf "%-25s%-10s%-10s%-12s%-12s%-10s%-10s%-10s\n",$1,$2,$3,$4,$5,$6,$7,$8}'
done

#stocktwits.com
$mycurl -X GET https://api.stocktwits.com/api/2/streams/symbol/$1.json > tmp 
echo "Stockwits Bull Time--Investor--------------------#Ideas--#Followers--#Likes"
cat tmp |jq '.messages[]|select(.entities.sentiment.basic=="Bullish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}'
echo "Stockwits Bear Time--Investor--------------------#Ideas--#Followers--#Likes"
cat tmp |jq '.messages[]|select(.entities.sentiment.basic=="Bearish") | [.created_at, .user.username, .user.ideas, .user.followers, .user.like_count]'\
|tr -d '\n' |sed 's/]/\n/g' |sed -e 's/\[//g' -e 's/"//g' -e 's/ //g' |awk -F',' '{printf "%s %-25s %8d %10d %8d\n",$1,$2,$3,$4,$5}'

#fool recent picks 
echo "Fool Pick Date--Player--------------Rating---------------------------------"
egrep "^$1,"  foolrecentpick.csv |grep -v '.aspx' |awk -F',' '{printf "%-16s%-20s%-9s\n",$5,$3,$4}'

#Marketwatch games
echo "Buy/Short--Holding%--#Rank in a MarketWatch Game---------------------------"
egrep "^$1,"  marketwatchgames.csv  |awk -F',' '{printf "%-12s%-10s%-10s\n",$3,$2,$4}'

gurufocus=$(egrep -w $1 gurufocus.csv)
[[ ! -z $gurufocus ]] && echo "GuruFocus Latest Buy"