import requests
import sys
from fake_useragent import UserAgent
import re
import time
from pandas_datareader import data as pdr

all_symbols = pdr.get_nasdaq_symbols()                       
nyse_nasdaq=all_symbols[(all_symbols['Listing Exchange'].isin(['A', 'N'])) &  #A: NYSE N:NASDAQ 
                        (all_symbols['ETF'] == False) &  #NOT ETF
                        (all_symbols.index.str.match(r'^[A-Z]{1,4}$'))  & #exclude .U/-A/-B/.. tickers
                        (all_symbols.index.str.contains('^CB'))
                        ] 

tickers=nyse_nasdaq.index.tolist()[0:100] #test with short list without tor
#etfdb.com throttling/block repetitive screen-scraping after 200-300 requests
#Use tor to anomalize requests for all listings (~3000)
#apt install tor; service tor start; 
#(optional) apt install build-essential libssl-dev libffi-dev python-dev
#tickers=nyse_nasdaq.index.tolist() #full list with tor

for ticker in tickers:  
  sys.stdout.flush() #to python <this>|tee to a output file
  try: #some ticker is listed as a stock, but is actually a NOTEs w/o MarketCap (e.g., AQNA)
    marketcap=pdr.get_quote_yahoo([ticker])['marketCap'][0]
    if (marketcap<1000000000): 
      continue #skip market cap less than $1B  

    #short listing without tor:
    html=requests.get("https://etfdb.com/stock/"+ticker+"/",allow_redirects=False).text 
    #full  listing with tor:
    #proxies = { #tor proxy on localhost
    #  'http': 'socks5://127.0.0.1:9050',
    #  'https': 'socks5://127.0.0.1:9050'
    #}
    #headers = {'User-Agent':UserAgent().random} #add more randomness in header.
    #html=requests.get("https://etfdb.com/stock/"+ticker+"/",headers=headers,proxies=proxies,allow_redirects=False).text 

    etfs=re.findall("data-th=\"ETF\"><a href=\"\/etf\/[A-Z]+\/\">",html)
    weights = re.findall("data-th=\"Weighting\">[0-9]+\.[0-9]+%", html)  
    if weights: #if ticker is constituent stock of any ETFs, pick one with max weight.
      print (ticker,etfs[0].split("/")[2],weights[0].split(">")[1])
    else:
      print (ticker)
  except KeyError as key_error: 
    print (ticker+" KeyError") #skip none-stock (NOTEs/...) listed on NYSE/NASDAQ
  except IndexError as index_error:     
    print (ticker+" IndexError")