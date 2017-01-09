#!/bin/sh

\rm -f covester.log fool.log marketocracy.log thelion.log
./covestor.sh > covestor.log
./fool.sh 
./marketocracy.sh

thisyear=`date +%Y`
lastyear=`echo $thisyear - 1 | bc`
./thelion.sh |egrep -v "Closed" |egrep "$thisyear|$lastyear" > thelion.log
#./marketwatchgames.sh #take long to complete. do it once a while 
