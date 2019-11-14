
mycurl="curl -stderr -L -k -A 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1'"
$mycurl "https://seekingalpha.com/stock-ideas/long-ideas" |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]' > seekingalphalong.csv
