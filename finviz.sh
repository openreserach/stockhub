#!/bin/bash

curl "http://www.finviz.com/quote.ashx?t=$1" >tmp$$

cat tmp$$ |grep center |grep target |egrep -o  "<b>[A-Za-z.' ]+</b>" |sed -e 's/<b>//g' -e 's/<\/b>//g'
cat tmp$$ |grep "fullview-links" |grep tab-link |egrep -o ">[A-Za-z0-9[:space:]\-]+<\/a>" |cut -d'>' -f2 |cut -d'<' -f1 |tr '\n' ' '
echo " "
for key in 'Market Cap' 'P/E' 'Forward P/E' 'P/C' 'P/FCF' 'P/B' 'Debt/Eq' 'Current Ratio' 'ROA' 'ROE' 'EPS next 5Y' 'Dividend %'
do
    cat tmp$$ |grep ">$key<" |sed 's/<b>/\n/g' |tail -n 1 |egrep -o '#[a-z]+[0-9]+|[0-9]+.[0-9]+' > tmp1$$
    color=`cat tmp1$$ |head -n 1`
    val=`cat tmp1$$ |tail -n 1`
    if [ "$color" == '#aa0000' ]; then 
	echo -e "$key:\t\t\e[00;31m$val\e[00m" 
    elif [ "$color" == '008800' ]; then 
 	echo -e "$key:\t\t\e[00;32m$val\e[00m" 
    else 
	echo -e "$key:\t\t$val"
    fi
done

rm tmp$$
