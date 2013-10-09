require 'net/http'

#Show covestor.com high performance investor's portfolio and their buy/sell actions

minrisk=1 #portfolio risk range from 1-5(highest)
maxrisk=4 
web_proxy=Net::HTTP::Proxy('firewall', 80) #if behind firewall, specify your HTTP proxy here

for page in 1..10 # fetch top investor's portfolio in first 10 pages
	_page= (page==1)? ('?') :('page/'+page.to_s+'/?')
	url='http://search.covestor.com/'+_page+'orderby=performance&portfoliotype=singlemanager&riskscoremax='+maxrisk.to_s+'&riskscoremin='+minrisk.to_s
	overview=web_proxy.get_response(URI.parse(url))
	overview.body.scan(/http:\/\/covestor\.com\/[a-zA-Z-]+\/[a-zA-Z-]+/).sort.uniq.each do |line|
		manager=line.split(/\//)[3] #manager's name
		fund=line.split(/\//)[4]	#fund's name manager-to-fund is 1-to-m
		transaction=web_proxy.get_response(URI.parse(line))
		freq=transaction.body.match(/Average trades per month [0-9.]+/).to_s.match(/[0-9.]+/).to_s #trade frequency per month
		perm=transaction.body.scan(/Past 30 days\<\/td\>\n\s+\<td class=\"numeric\"\>[0-9.]+%/).to_s.match(/[0-9]+.[0-9]%/).to_s #average monthly gain/loss

		dates = Array.new
		transaction.body.scan(/"title">[0-9]{2}\/[0-9]{2}\/[0-9]{2}/).each do |date|	
			dates<<date.to_s.match(/[0-9]+\/[0-9]+\/[0-9]+/).to_s	#transaction date 			
		end
		buysells=Array.new
		transaction.body.scan(/^\s+Buy to cover\s+$|^\s+Sell short\s+$|^\s+Buy\s+|^\s+Sell\s+$/).each do |buysell|
			buysells<< buysell.strip.gsub(" ", "-") #actions
		end
		stocks=Array.new
		transaction.body.scan(/http:\/\/stocks\.covestor\.com\/[a-z]+" title=/).each_with_index do |stock,index|
			if index % 2 ==0 
				stocks<<stock.to_s.split(/\//).last.upcase.split(/"/).first							
			end	
		end
		prices=Array.new
		transaction.body.scan(/\$[0-9]+\.[0-9]+/).each do |price|
			prices<<price
		end		
		
		dates.each_with_index do |date,index|
			printf("%70s %8s %8s %12s %8s\n",manager+' '+fund+' '+freq+' '+perm,dates[index],prices[index],buysells[index],stocks[index])			
		end				
	end
end
