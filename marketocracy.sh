
export log="marketocracy.log"

echo "Stock, Manager, WinningRatio" > $log
curl "http://www.marketocracy.com/managers.php?type=masters" |grep -i manager |egrep -o "track\[[0-9]+\]" |cut -d'[' -f2 |cut -d']' -f1 |while read id
do
    curl "http://www.marketocracy.com/process/ajax/path-session.php?process=get-manager&manager=$id" > tmp
    export manager=`cat tmp |egrep -a "<h1>" |sed -e 's/<h1>//g' -e 's/<\/h1>//g' |sed "s/^[ \t]*//"`
    export winningratio=`cat tmp |egrep -a -A 1 "Winning" |tail -n 1 |egrep -o "[0-9.%]+"`
    cat tmp |egrep -a -o 'symbol">[A-Z]+'  |sed s'/symbol">//g' |while read stock
    do
	echo $stock, $manager, $winningratio >> $log
    done
done

#cat tmpmarketocracy |sort |uniq > $log

