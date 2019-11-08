#!/bin/bash

mycurl="curl -stderr -L -k -A 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1'"
mychrome="google-chrome-stable --headless --disable-gpu --dump-dom" #headless browser to deal with more javascript

$mycurl "https://www.finviz.com/quote.ashx?t=$1" > tmp
cat tmp|grep "<title>" |cut -d'>' -f2 |cut -d'<' -f1 |sed 's/Stock Quote//g'
cat tmp|grep center |grep fullview-links |grep tab-link |cut -d'>' -f4,6,8 |sed 's/<\/a/ /g'
cat tmp|grep "Current stock price" |cut -d'>' -f5- |cut -d'<' -f1
$mycurl "https://finance.yahoo.com/quote/$1"  |egrep -o  'data[Red|Green]+\)" data-reactid="[0-9]+">\S+\s+\([+|-][0-9.%]+\)' |cut -d'(' -f2 |cut -d')' -f1
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

echo "Rating================================"
export sp500avgpe=`$mycurl https://www.multpl.com/ |egrep -o "Current S&P 500 PE Ratio is [0-9.]+" |rev |awk '{print $1}' |rev`
echo -e "S&P 500 avg PE:" $sp500avgpe
#gurufocus biz predicability
export predstar=`$mycurl "https://www.gurufocus.com/gurutrades/$1" |egrep -o "aria-valuenow=\"[0-9]" |cut -d'"' -f2`
echo -e "Predictability:\t" $predstar

#Crammer's MadMoney comments
export madmoneyurl="https://madmoney.thestreet.com/07/index.cfm?page=lookup"
export madmoneylookup="symbol=$1"
$mycurl -d $madmoneylookup $madmoneyurl |tac |tac |egrep -m 1  ">[0-9]{2}/[0-9]{2}/200?" -A 20 >tmp #care the latest one
export maddate=`cat tmp |egrep -o "[0-9]{2}/[0-9]{2}/20[0-9][0-9]"`
export madbuysell=`cat tmp |egrep -o "[1-5]\.gif"|sed 's/.gif//g' |sed 's/5/SB/g'|sed 's/4/B/g'|sed 's/3/H/g'|sed 's/2/S/g'| sed 's/1/SS/g'`
export madvalue=`cat tmp |egrep -o "[0-9]+\.[0-9]+"|head -n 1`
export madchange=`cat tmp |egrep -o "\+ [0-9]+\.[0-9]+%|\- [0-9]+\.[0-9]+%"|tail -n 1`
echo -e "Crammer:\t"$maddate $madbuysell $madvalue $madchange

export zack=`$mycurl "https://www.zacks.com/stock/quote/BAC" |egrep -m1 "rank_chip" |cut -d'<' -f1 |sed 's/ //g'`
if [ ${zack} ]
then
	echo -e "Zack Rank:\t"$zack
fi
#stoxline rating
export stoxline=`$mycurl "http://m.stoxline.com/stock.php?symbol=$1" |grep -A 2 "Overall" |egrep "pics/[0-9]s.png" |egrep  -o '[0-9]s.png' |sed 's/s.png/ stars/g'`
echo -e "Stoxline:\t"$stoxline

#Argus Research from Yahoo
$mychrome "https://finance.yahoo.com/quote/$1" > tmp 2>&1
recommendation=`cat tmp |egrep -o 'data-reactid="11">[A-Za-z ]+<\/span>'  |grep -v -i help |cut -d'>' -f2 |cut -d'<' -f1`
fairvalue=`cat tmp |egrep -o 'data-reactid="29">[A-Za-z ]+<' |cut -d'>' -f2 |cut -d'<' -f1 `
echo -e "Argus Research:\t"$recommendation
echo -e "Fair Value:\t"$fairvalue

#MotleyFool's rating to be replace motley api
if [ ${FOOL_API_KEY} ] 
then  #apply for your own free key at http://developer.fool.com/, and set it in environment variable FOOL_API_KEY
	export star=`$mycurl "http://www.fool.com/a/caps/ws/Ticker/$1?apikey=$FOOL_API_KEY" |egrep -o 'Percentile="[0-5]"' |egrep -o "[0-5]"`
	echo -e "MotelyFool:\t"$star
fi
$mycurl "http://x-fin.com/stocks/screener/graham-dodd/"    |egrep -A 1 "The complete list of" |egrep -o -w $1 |sed "s/$1/Graham-Dodd-Value/g"
$mycurl "http://x-fin.com/stocks/screener/graham-formula/" |egrep -A 1 "The complete list of" |egrep -o -w $1 |sed "s/$1/Graham-Formula-Value/g"
$mycurl "https://seekingalpha.com/stock-ideas/long-ideas"  |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |tr [:lower:]  [:upper:]|egrep -w "$1$" | sed "s/$1/SeekingAlpha\tLong/g"

echo "TA & Trend ==================================="
export trenspotter=`$mycurl "https://www.stockta.com/cgi-bin/analysis.pl?symb=$1&cobrand=&mode=stock" |grep -i 'class="analysisTd' |grep -v Intermediate |egrep -o ">[A-Za-z]+ \([-0-9.]+\)" |tr '>' '|' |head -n 1 |cut -d'|' -f2`
echo -e "Overall Trend:\t"$trenspotter
#TA pattern
export signal=`$mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker=$1" |grep "MainContent_LastSignal"|egrep -o ">[A-Z ]+</font>" |cut -d'<' -f1|cut -d'>' -f2`
export pattern=`$mycurl "https://www.americanbulls.com/SignalPage.aspx?lang=en&Ticker=$1" |egrep "MainContent_LastPattern" |cut -d'>' -f3 |cut -d'<' -f1  |sed 's/NO PATTERN//g' |tr -d '\r\n'`
if [ ${single} ] 
then
	echo -e "USBull Signal\t"$signal 
fi
if [ ${pattern} ]
then
	echo -e "USBull Pattern\t"$pattern
fi
pretiming=`$mycurl "https://www.pretiming.com/search?q=$1" |egrep -A 5  -m1 "Recommended Positions"  |tail -n 1 |egrep -o -i "long-bullish|long-bearish|short-bullish|short-bearish"`
if [ ${pretiming} ] 
then
	echo -e "PreTiming TA:\t"$pretiming
fi

echo "Radar Screen================================="
echo -n "Fool Players: "
$mycurl "https://caps.fool.com/Ticker/$1/Scorecard.aspx" |egrep -m1 -A 18 "http://caps.fool.com/player" |egrep -v "<" |tr -d '\040\011' |awk 'NF' |tr '\n' ',';echo

#Trading view
$mycurl https://www.tradingview.com/symbols/NYSE-$1 > tmp
$mycurl https://www.tradingview.com/symbols/NASDAQ-$1 >> tmp
trader=$(cat tmp |egrep 'tv-card-user-info__name">' |head -n 1 |rev |cut -d'>' -f2 |rev |cut -d'<' -f1)
idea=$(cat tmp |egrep '"tv-idea-label__icon' |head -n 1 |rev |cut -d'>' -f1-3 |rev |cut -d'<' -f1)
timeframe=$(cat tmp |egrep '__timeframe"' |head -n 1 |cut -d',' -f2 |cut -d'<' -f1 |sed 's/ //g')
date=$(date -d @`cat tmp |egrep "data-timestamp=" |head -n 1 |rev  |cut -d'=' -f1 |rev |cut -d'>' -f1 |sed 's/"//g'`  +"%m/%d/%Y")
echo "Trader view:"$trader,$idea,$timeframe,$date

