#!/bin/bash

if [ $# -ne 1 ]; then
   export window=7 #one week window
else
   export window=$1  #take days from command line
fi
echo "Commonly bought stocks in last $window days"
\rm -f tmpcommon*
\rm -f tmpm*ddyy*


>tmpmmddyyyy
>tmpmmddyy
for day in `seq 1 $window` 
do
    date -d "$day day ago" +%m/%d/%Y >> tmpmmddyyyy
    date -d "$day day ago" +%m/%d/%y >> tmpmmddyy
done
mmddyyyy=`cat tmpmmddyyyy |tr '\n' '|' |sed -e 's/|$//'`
mmddyy=`cat tmpmmddyy     |tr '\n' '|' |sed -e 's/|$//'`
mddyy=`cat tmpmmddyy      |tr '\n' '|' |sed -e 's/|$//' -e 's/0//g'` #format different dates for different logs


cat thelion.log     |egrep $mmddyyyy |grep "Buy"  |awk '{print $2}' > tmpcommonlion
cat fool.log        |egrep $mmddyy                |awk '{print $4}' > tmpcommonfool
cat covestor.log    |egrep $mmddyyyy |grep "Buy"  |awk '{print $1}' > tmpcommoncovestor
cat marketwatch*.log|egrep $mddyy    |grep "Buy"  |cut -d':' -f2- |awk '{print $1,$3}' |sort |uniq |awk '{print $2}' |sort |uniq -d > tmpcommonmarkwatch

cat tmpcommonlion tmpcommonfool tmpcommoncovestor tmpcommonmarkwatch |sort |uniq -d #find commonly bought stock from different logs.




