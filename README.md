
/stockhub
========
"stockhub" is a suite of scripts that web-crawl investment sites, and present trading ideas shared by high-performing/rating investors/professionals with track records.

It fetches/normalizes live data (in HTML/JSON/CSV/... formats) from publicly-accessible sites, including but not limited to, ARK-investments; Ongoing games/competitions hosted by MotleyFool/MarketWatch; SeekingAlpha; SEC 13F filers; famous youtubers on stocks. It is designed as a light-weighted tool that can be executed on any Linux-compatible command-line console, e.g., repl.it console in a web browser; Linux Subsystem (WLS)/Cygwin on Windows; Amazon EC2 (micro/free) Linux instance; etc. For example, 
https://repl.it --> login with google credential --> My Repls --> New Repl --> Import from Github --> https://github.com/openreserach/stockhub.git --> run script in console/shell tab.

1. fetch.sh takes ~5 minutes to crawl all investment sites, and generate investors' holdings/transactions in *.csv format. It also shows current economic and market overview (e.g., S&P500 average PE, Fear/Greed index,... ) while fetching data. For example,
./fetch.sh 
Economic & Market Overview====================
S&P500 PE Average:              37.61
FearGreed (0-100):              50 (Neutral)
Index  Put/Call Ratio:          1.53
Equity Put/Call Ratio:          0.47
Personal Saving Rate:           12.9%
Crash Confidence Index:			16.57
Customer Securities Debit:      722,118
Buffett Indicator:              185.6%
VIX (current):                  22.77
OFR Financial Stress Index:     -3.681
AAII Bullish|Neutral|Bearish:   43.6%|34.4%|22.0%|
....................................................Complete

2. commonbuystocks.sh shows "most commonly(numered)" buys with given time periods (~in last 7 days), and an ETF (if any) a stock has the largest exposure/weight.
./commonbuystocks.sh 
Sources Ticker    ETF   Weight
    7    AAPL     XLK  24.90%
    6    TSLA     IYK  16.38%
    6    BABA    ADRE  17.64%
    5       U    LRNZ   5.57%
    5    TDOC    ENTR   4.44%
    5    MSFT     XLK  19.39%
    5    INTC    SOXX   7.56%
    5     FIS    IPAY   5.39%
    5     CVS     IHF  11.62%
	..........................

3. rating.sh is the primary tool to show a stock's fundamentals/technicals, ratings and news from different sources. It also shows "what people say" (from social media) and "what people do" (purchases made by investors with verifiable rating/performance). For example, 
./rating.sh AAPL
AAPL Apple Inc. >Technology>Consumer Electronics>USA
$133.72 -0.85% 12/31/2020
Fundamentals--------------------------------
Market Cap      2256.08B
P/E             40.93
Forward P/E     30.83
P/S             8.22
PEG             3.24
P/FCF           38.06
Current Ratio   1.40
.....................
Earnings        Oct 29
Earning Surprise ++++++++++++
Last Rating:    12/16/20 Morgan Stanley Maintains Overweight 144.0
ETF/Weight:     XLK 24.90%
Valuations------------------------------------
DCF(Earn/FCF):  72.19/92.5
EV/EBITDA:      28.57
Rule-of-40%:    26.43%
GuruFocus:      $64.59
Yahoo:          Overvalued
Ratings-------------------------------------------
Strength:       6/10
Profitability:  9/10
Valuation:      1/10
Crammer:        12/22/2020,Buy,$131.88,
Stoxline:       3 stars
MotelyFool:     4 out of 5
TR Score:       10 Bullish:84% Sentiment:buy
PriceTarget:    $131.88|Buy|Hold|Sell:23|6|1
Technical & Trend ----------------------------------
Overall Trend:  Bullish (0.46)
Candle Stick:   Neutral Bearish Engulfing
Chart Signal:   Strong buy
News>Dec-29-20==================================================================================================
1   Heres How to Prepare Your Portfolio for the New Year, According to Charles Schwabs Liz Ann Sonders
2   Apple iPhones Take 9 of Top 10 Spots in Activations on Xmas Day
.................
What people say(social media)====================================================================================
TradingviewUser               LongShort YYYYMMDD  TradeWindow Reputation  #Ideas    #Likes    #Followers
TheSignalyst                  short     20201229  60          5917        625       7023      1554      
ch33zy                        long      20201230  240         25          82        104       42        
.................
Expert Name--------------Rating-Return%-YYYY-MM-DD-----URL---------------------------Title------------------
Will Ashworth              5    32.9    2020-12-30     https://tinyurl.com/yaocja5k  7 Music Stocks Ready to Party
Harsh Chauhan              5    23      2020-12-30     https://tinyurl.com/ybbvl4pt  Why Apple Could Be a Top Growth Stock in 2021
.................
SeekingAlpha-------------------------------------------------------------------------
https://tinyurl.com/yckhtm2u
What people do===================================================================================================
Fool Player-------------------Rating--MM/DD/YYYY--Time--StartPrice--URL---------------
phc19                         95.85   12/30/2020  5Y    $135.57     https://caps.fool.com/player/phc19.aspx
ebarrocas                     60.66   12/30/2020  5Y    $134.22     https://caps.fool.com/player/ebarrocas.aspx
.................
Buy/Short---Date------#Rank----MarketWatch Game---------------------------
Sell        12/30/20  48       https://tinyurl.com/yb2m229k
Buy         12/30/20  48       https://tinyurl.com/yb2m229k
ARK :Significant(>1%) change(+/-/0) in the fund in last 30 days----------------------------
ARKW:+00000
ARKQ:0++++0+0+00+++0+0+++0+00
ARKG:000000000
ARKF:0+++0++0+00++++++0+++0+0
Recent 13F filers by whaleswisdom-------------------------------------LastQ---LastY---
Add:AAPL  advisory-resource-group                                     26.21%  -6.72%  
Add:AAPL  bbk-capital-partners-llc                                    4.67%   4.63%   
.................
QQ-YYYY-13F filers by dataroma----------------------------------------Action----------
Q3 2020 Lee Ainslie - Maverick Capital                                Add 11300.00%  
Q3 2020 Thomas Russo - Gardner Russo & Gardner                        Add 11.15%     
...................

./