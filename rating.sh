#!/bin/bash
#clear
>tmp$$

quote=`./quote.sh $1|cut -d':' -f2|awk '{print $1}'`
echo $1=$quote

echo "FA================================"
./finviz.sh $1
echo "================================"
#MSN StockScouter
curl "http://moneycentral.msn.com/investor/StockRating/srsmain.asp?Symbol=$1" > tmp$$
#export MSNStockScouter=`cat tmp$$ |egrep  "SRS[0-9]" |cut -d"." -f1|cut -d"/" -f2 |cut -c 4-5`
export MSNStockScouter=`cat tmp$$ |egrep  -o "StockScouter Rating: [0-9]{1,2}" |cut -d':' -f2 |sed 's/ //g'`
export Fudamental=`cat tmp$$ |grep -i Fundamental |grep -o ">[A-F]<" |cut -c 2`
export Ownership=`cat tmp$$ |grep -i Ownership |grep -o ">[A-F]<" |cut -c 2`
export Valuation=`cat tmp$$ |grep -i Valuation |grep -o ">[A-F]<" |cut -c 2`
export Technical=`cat tmp$$ |grep -i Technical |grep -o ">[A-F]<" |cut -c 2`
echo -e "MSN Rating:\t"$MSNStockScouter

#Crammer's MadMoney comments
export madmoneyurl="http://madmoney.thestreet.com/07/index.cfm?page=lookup"
export madmoneylookup="symbol=$1"
curl -d $madmoneylookup $madmoneyurl |egrep -m 1  ">[0-9]{2}/[0-9]{2}/200?" -A 20 >tmp1$$ #care the latest one
export maddate=`cat tmp1$$ |egrep -o "[0-9]{2}/[0-9]{2}/20[0-9][0-9]"`
export madbuysell=`cat tmp1$$ |egrep -o "[1-5]\.gif"|sed 's/.gif//g' |sed 's/5/SB/g'|sed 's/4/B/g'|sed 's/3/H/g'|sed 's/2/S/g'| sed 's/1/SS/g'`
export madvalue=`cat tmp1$$ |egrep -o "[0-9]+\.[0-9]+"|head -n 1`
export madchange=`cat tmp1$$ |egrep -o "\+ [0-9]+\.[0-9]+%|\- [0-9]+\.[0-9]+%"|tail -n 1`
echo -e "Crammer:\t"$maddate $madbuysell $madvalue $madchange

#StoackTA analysis
export stocktaoverall=`curl "http://www.stockta.com/cgi-bin/analysis.pl?symb=$1&num1=2&cobrand=&mode=stock" |grep Short -A 1 |egrep -o ">[A-Za-z]+.[A-Za-z]+" | sed 's/>//g' |tail -n 4 |head -n 1`
echo -e "TA Trend:\t"$stocktaoverall
curl "http://download.finance.yahoo.com/d/quotes.csv?s=$1,SPY&f=m8" |cat -v |sed -e 's/%//g' -e 's/ //g' -e 's/\^M//g' |tr '\n' ' ' |awk '{print  "50MA vs. S&P:\t" $1" vs. "$2}'

#stoxline rating
export stoxline=`curl  -b "symbol=$1" "http://www.stoxline.com/quote.php?symbol=$1" |egrep -o "[1-5]s.bmp" |sed 's/s.bmp//g' |sed -e 's/1/Strong Sell/g' -e 's/2/Sell/g'  -e 's/4/Neutral/g' -e 's/3/Buy/g' -e 's/5/Strong Buy/g'`
echo -e "Stoxline:\t"$stoxline

#MotleyFool's rating
export star=`curl "http://caps.fool.com/Ticker/$1.aspx" |grep -A 2 "CAPS Rating" |egrep -o "[0-9] out of 5" |awk '{print $1}'`
echo -e "MotelyFool:\t"$star

#Trend Spotter
trenspotter=`curl "http://www.stockta.com/cgi-bin/opinion.pl?symb=$1&num1=4&mode=stock"|sed 's/TR/\n/g' |grep "Trend Spotter"  |egrep -o ">Buy<|>Sell<|>Hold<" |sed -e 's/>//g' -e 's/<//g'`
echo -e "Trend Spotter:\t"$trenspotter

#Stock Picker rating
upper=`echo $1|tr a-z A-Z`
curl "http://www.stockpickr.com/symbol/$upper" |egrep "ratings" |grep "summary" |cut -d'>' -f4 |cut -d'<' -f1 |while read line
do
    echo -e "Stockpickr:\t"$line
done

#Social Picker's rating; slow and comments out
curl "http://www.socialpicks.com/stock/$upper/sentiment" > tmp$$
socialpicker=`cat tmp$$ |egrep -B 3 "\([0-9]+ ratings\)" |head -n 1 |cut -d'>' -f3- |cut -d'<' -f1`
socialstar=`cat tmp$$ |egrep -o "graphic_star_big.gif" |wc -l`
socialhalfstar=`cat tmp$$ |egrep -o "graphic_star_big_half.gif" |wc -l`
socialstarnum=`echo "scale=1;$socialstar + $socialhalfstar/2" |bc`
echo -e "SocialPicker:\t"$socialpicker" "$socialstarnum" stars"

#GStock
export lower=`echo $1|tr A-Z a-z`
curl http://www.gstock.com/quote/$lower.html |egrep -o "BUY|SELL"  |head -n 1 |while read line
do
    echo -e "GStock ALert:\t" $line
done

#guru focus fair value
curl "http://www.gurufocus.com/StockBuy.php?symbol=$1" |egrep -A 1  "Fair Value"  |tail -n 1 |egrep -o '>\$[0-9]+.[0-9]+<' |sed -e 's/>//g' -e 's/<//g'|while read line
do
   echo -e "GuruFairValue:\t" $line
done

#TA pattern
americanbull=`./americanbulls.sh $1`
echo -e "Candlestick:\t$americanbull"
curl http://www.datawm.com/nastocks/clearstation-outputFile.txt |grep  "|$1$" |cut -d'|' -f2 |while read ta
do
    echo -e "Clearstation:\t$ta"
done

echo "Covestor Top Manager Current Holdings====================="
echo -e "Manager\t\t\t\tFund\t\tReturn"
minrisk=1
maxrisk=5
duration='365d'
for page in {1..10}
do
curl "http://search.covestor.com/page/$page?orderby=$duration&riskscoremin=$minrisk&riskscoremax=$maxrisk"  |egrep -o "http://covestor.com/[a-zA-Z-]+/[a-zA-Z-]+" |uniq |while read line
do
    manager=`echo $line |cut -d'/' -f4`
    fund=`echo $line |cut -d'/' -f5`
    curl $line > tmp$$
    perf=`cat tmp$$  |grep -A 1 "Past 30 days" |egrep -o "[0-9]+.[0-9]+%"`
    curl "$line/holdings" |egrep "value-[0-9]" |grep -v -i replicable |grep span |cut -d'>' -f4 |cut -d'<' -f1 |grep $1 |while read stock 
    do
	echo $manager $fund $perf |awk '{printf "%-30s%-30s%-6s\n", $1,$2,$3}'
    done
done
done


echo "Radar Screen----------------------------------------"
curl "http://www.grahaminvestor.com/screens/graham-intrinsic-value-stocks/" |egrep -o 'bc\?s=[A-Z.]+'|cut -d'=' -f2 |egrep -w "$1$" |sed "s/$1/Graham Intrinsic Value/g"
curl "http://www.grahaminvestor.com/screens/low-price-to-operating-cash-flow-ratio/" |egrep -o 'bc\?s=[A-Z.]+'|cut -d'=' -f2 |egrep -w "$1$" |sed "s/$1/Low Price to Operating CashFlow Raio/g"
curl "http://www.insidercow.com/notLogin/buyByCompany.jsp" |egrep -o "company=[A-Z]+" |sort |uniq |cut -d'=' -f2 |egrep -w "$1$" |sed "s/$1/Insider Buy/g"

\rm -f tmp$$*

