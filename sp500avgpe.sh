#!/bin/sh

>tmp$$
curl 'http://en.wikipedia.org/wiki/List_of_S&P_500_companies' |grep getcompany |cut -d'=' -f5 |cut -d'&' -f1 |sort |uniq |while read line
do
    curl "http://finance.yahoo.com/q/ks?s=$line"  |sed 's/\<td/\n/g' |grep "Forward P/E" -A 3 |egrep -o ">[0-9]+.[0-9]+|N/A" |sed -e 's/>//g' >> tmp$$
done
cat tmp$$ |grep -v 'N/A' |grep -v "," > tmp # filter out no-PE and those are ridiculous high 1000+
count=`wc -l tmp |awk '{print $1}'`
cat tmp |tr '\n' '+' |sed 's/+$/\n/g' > tmp$$
allpe=`cat tmp$$ |bc`
avgpe=`echo "scale=2; $allpe/$count" |bc`
echo "SP500 Avg Forward P/E="$avgpe "IMHO, it is cheap (in) if <16.0, expensive (out) if > 17.0"
rm tmp tmp$$
