#!/bin/sh

#Find intersection of all traders' transaction given $days ago
if [ $# -ne 1 ]; then #if no argument assume yesterday
    export thedate=` date -d "1 day ago" +/%m/%d/%Y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2-`
else #otherwise 2,3,4.. days ago 
    export thedate=`date -d "$1 day ago" +/%m/%d/%Y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2- `
fi

cat *.log |egrep "$thedate" |uniq #find common transactions from fetch.sh
