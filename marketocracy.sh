
export log="marketocracy.log"


curl "http://www.marketocracy.com/managers.php?type=masters" |grep -i manager |egrep -o "track\[[0-9]+\]" |cut -d'[' -f2 |cut -d']' -f1 |while read id
do
    curl "http://www.marketocracy.com/process/ajax/path-session.php?process=get-manager&manager=$id" |egrep -o 'symbol">[A-Z]+'  |sed s'/symbol">//g' >> tmpmarketocracy
done

cat tmpmarketocracy |sort |uniq > $log

