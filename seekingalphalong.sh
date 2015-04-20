
curl "http://seekingalpha.com/analysis/investing-ideas/long-ideas" |grep bull |egrep -o "\/symbol\/[a-z]+"  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]'
