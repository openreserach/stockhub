#!/bin/bash

export http_proxy="firewall:80"
export mycurl="curl -stderr"

url="http://download.finance.yahoo.com/d/quotes.csv?s=$1&f=sl1p2cn"
$mycurl $url |cut -d',' -f1-3 

url="http://investing.money.msn.com/investments/stock-price?Symbol=$1"
$mycurl $url |grep "MSN StockScouter" #|egrep "[0-9]{1,2} out of 10/"