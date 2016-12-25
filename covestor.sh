#!/bin/bash

curl "http://covestor.com/search/champions" |egrep -o "http://covestor.com/[a-zA-Z-]+/[a-zA-Z-]+" |sort |uniq > tmp0
curl "http://covestor.com/search" |egrep -o "http://covestor.com/[a-zA-Z-]+/[a-zA-Z-]+" |sort |uniq >> tmp0
for page in `seq 2 2`
do
    	curl http://covestor.com/search/page/$page  |egrep -o "http://covestor.com/[a-zA-Z-]+/[a-zA-Z-]+" |sort |uniq >> tmp0
done
cat tmp0 |sort |uniq |while read line
do
	curl $line > tmp
	manager=`echo $line|cut -d'/' -f4`
	fund=`echo $line |cut -d'/' -f5`	#fund's name manager-to-fund is 1-to-m
	freq=`cat tmp |egrep -o "Average trades per month [0-9.]+" |egrep -o "[0-9.]+"`
        perm=`cat tmp |egrep -A 1 'Last 365 Days' |egrep -o '\-[0-9]+.[0-9]+%|[0-9]+.[0-9]+%'`
	
	cat tmp |egrep 'labelCol">\w+ [0-9]+, [0-9]+<' |cut -d'>' -f2 |cut -d'<' -f1 |while read date; do date -d "$date" +%m/%d/%Y; done |cat -n > tmp1
 	cat tmp |egrep -o -i '>Buy<|>Sell<|>\w+Cover<|>\w+Short>' |sed -e 's/<//g' -e 's/>//g' |cat -n > tmp2
 	cat tmp |egrep '<td> <a href="http://stocks.covestor.com/\w+">[A-Z]+<' |cut -d'>' -f3 |cut -d'<' -f1 |cat -n > tmp3
	cat tmp|egrep 'numeric.+">\$[0-9]+.[0-9]+'  |egrep -o '\$[0-9]+.[0-9]+' |cat -n > tmp4
		
	join tmp1 tmp2 |join - tmp3 |join - tmp4 |while read line
	do
		echo $line $freq $perm $manager $fund  |awk  '{printf "%-10s %-10s %-10s %-10s %-10s %-10s %-30s %-20s\n", $4,$3,$5,$2,$6,$7,$8,$9}'
	done 		
done
\rm -f tmp*
