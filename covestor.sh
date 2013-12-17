#!/bin/bash

export minrisk=1 #portfolio risk range from 1-5(highest)
export maxrisk=4 

for page in `seq 1 20`
do
	[ $page -eq 1 ] && _page=? || _page='page/'$page'/?'
	url='http://search.covestor.com/'$_page'orderby=performance&portfoliotype=singlemanager&riskscoremax='$maxrisk'&riskscoremin='$minrisk
	curl $url |egrep -o "http://covestor.com/[a-zA-Z-]+/[a-zA-Z-]+" |sort |uniq |while read line
	do
		manager=`echo $line|cut -d'/' -f4`
		fund=`echo $line |cut -d'/' -f5`	#fund's name manager-to-fund is 1-to-m
		
		curl $line > tmp
		freq=`cat tmp |egrep -o "Average trades per month [0-9.]+" |egrep -o "[0-9.]+"`
		perm=`cat tmp |egrep -A 2 'Past 30 days</td>'|egrep -o '\-[0-9]+.[0-9]+%|[0-9]+.[0-9]+%'`
		
		i=0;>tmp1		
		cat  tmp |egrep 'title">[0-9]{2}/[0-9]{2}/[0-9]{2}' |egrep -o "[0-9]{2}/[0-9]{2}/[0-9]{2}" |while read date 
		do
			i=`echo $i+1 |bc`
			echo $i $date >> tmp1
		done
		i=0;>tmp2
		cat tmp |egrep -o '[[:space:]]Buy to cover[[:space:]]|[[:space:]]Sell short[[:space:]]|[[:space:]]Buy[[:space:]]|[[:space:]]Sell[[:space:]]'|tr -d ' ' |while read action
		do
			i=`echo $i+1 |bc`
			echo $i $action >> tmp2
		done
		
		i=0;>tmp3
		cat tmp |egrep -o '"http://stocks.covestor.com/[a-z]+" title="'|awk '{print $1}' |cut -d'/' -f4 |tr '"' ' ' | tr '[:lower:]' '[:upper:]'|while read stock 
		do
			i=`echo $i+1 |bc`
			j=`echo $i/2 |bc`
			if [ $(expr $i % 2) -eq 0 ]; then 
				echo $j $stock >> tmp3
			fi
		done
		
		i=0;>tmp4
		cat tmp|egrep 'numeric">\$[0-9]+.[0-9]+'  |egrep -o '\$[0-9]+.[0-9]+' |while read price
		do
			i=`echo $i+1 |bc`
			echo $i $price >> tmp4
		done
		
		join tmp1 tmp2 |join - tmp3 |join - tmp4 |while read line
		do
			echo $line $freq $perm $manager $fund  |awk  '{printf "%-10s %-10s %-10s %-10s %-10s %-10s %-30s %-20s\n", $4,$3,$5,$2,$6,$7,$8,$9}'
		done 		
	done
done
