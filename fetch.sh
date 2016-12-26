#!/bin/sh

\rm *.log
./covestor.sh > covestor.log
./marketwatchgames.sh
./fool.sh 

thisyear=`date +%Y`
lastyear=`echo $thisyear - 1 | bc`
./thelion.sh |egrep -v "Closed" |egrep "$thisyear|$lastyear" > thelion.log
