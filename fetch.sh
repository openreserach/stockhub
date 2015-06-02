#!/bin/sh

\rm *.log
./covestor.sh > covestor.log
./thelion.sh > thelion.log
./marketwatchgames.sh
