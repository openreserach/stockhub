
curl "http://seekingalpha.com/analysis/investing-ideas/long-ideas" |grep bull |egrep -o "\/symbol\/[a-zA-Z0-9\-\.]+"  |cut -d'/' -f3 |tr '[:lower:]' '[:upper:]'
