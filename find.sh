#!/bin/sh

#Find intersection of all traders' transaction given $days ago
if [ $# -ne 1 ]; then #if no argument assume yesterday
    export YYYYdate=` date -d "1 day ago" +/%m/%d/%Y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2-`
    export YYdate=` date -d "1 day ago" +/%m/%d/%y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2-`
else #otherwise 2,3,4.. days ago 
    export YYYYdate=`date -d "$1 day ago" +/%m/%d/%Y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2- `
    export YYdate=`date -d "$1 day ago" +/%m/%d/%y| sed 's/\/0/\/(0)?/g' |sed 's/\/20/\/(20)?/g' |cut -c2- `
fi

cat covestor.log | egrep "$YYYYdate"
#cat *.log |grep -v "Closed" |egrep "$thedate" |uniq #find common transactions from fetch.sh

cat covestor.log 	| egrep "$YYYYdate" 	|awk '{print $1}' > tmpcommon 
cat marketwatch*.log  	| egrep "$YYdate" 	|awk '{print $3}' |sort |uniq >> tmpcommon 
cat fool.log 		| egrep "$YYdate" 	|awk '{print $4}' >> tmpcommon
cat thelion.log 	| egrep "$YYYYdate" 	|awk '{print $2}' >> tmpcommon

cat tmpcommon |sort |uniq -d |while read stock
do
    echo "Common:"$stock
done
