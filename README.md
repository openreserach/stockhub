
/stockhub
========
"stockhub" is a suite of scripts that web-crawl investment sites, and present trading ideas shared by high-performing/rating investors/professionals with track records.

It fetches/normalizes live data (in HTML/JSON/CSV/... formats) from publicly-accessible sites, including but not limited to, ARK-investments; Ongoing games/competitions hosted by MotleyFool/MarketWatch; SeekingAlpha; SEC 13F filers; famous youtubers on stocks. It is designed as a light-weighted tool that can be executed on any Linux-compatible command-line console, e.g., repl.it console in a web browser; Linux Subsystem (WLS)/Cygwin on Windows; Amazon EC2 (micro/free) Linux instance; etc. For example, 

https://repl.it --> login with google credential --> My Repls --> New Repl --> Import from Github --> https://github.com/openreserach/stockhub.git --> run script in console/shell tab.

1. fetch.sh takes ~5 minutes to crawl all investment sites, and generate investors' holdings/transactions in *.csv format. It also shows current economic and market overview (e.g., S&P500 average PE, Fear/Greed index,... ) while fetching data. For example,

./fetch.sh <br/>
Economic & Market Overview==================== <br/>
S&P500 PE Average:&emsp;&emsp;	37.61 <br/>
FearGreed (0-100):&emsp;&emsp;	50 (Neutral) <br/>
Index  Put/Call Ratio:&emsp;&emsp;1.53<br/>
Equity Put/Call Ratio:&emsp;    0.47<br/>
Personal Saving Rate:&emsp;     12.9%<br/>
Crash Confidence Index:&emsp;	16.57<br/>
Customer Securities Debit:&emsp;722,118<br/>
Buffett Indicator:&emsp;        185.6%<br/>
VIX (current):&emsp;            22.77<br/>
OFR Financial Stress Index:&emsp;-3.681<br/>
AAII Bullish|Neutral|Bearish:&emsp;43.6%|34.4%|22.0%|<br/>
....................................................Complete<br/>
<br/>
2. commonbuystocks.sh shows "most commonly(numered)" buys with given time periods (~in last 7 days), and an ETF (if any) a stock has the largest exposure/weight.
./commonbuystocks.sh <br/>
Sources Ticker    ETF   Weight<br/>
    7    AAPL     XLK  24.90%<br/>
    6    TSLA     IYK  16.38%<br/>
    6    BABA    ADRE  17.64%<br/>
    5       U    LRNZ   5.57%<br/>
    5    TDOC    ENTR   4.44%<br/>
    5    MSFT     XLK  19.39%<br/>
    5    INTC    SOXX   7.56%<br/>
    5     FIS    IPAY   5.39%<br/>
    5     CVS     IHF  11.62%<br/>
	..........................<br/>

3. rating.sh is the primary tool to show a stock's fundamentals/technicals, ratings and news from different sources. It also shows "what people say" (from social media) and "what people do" (purchases made by investors with verifiable rating/performance). For example, 
./rating.sh AAPL<br/>
AAPL Apple Inc. >Technology>Consumer Electronics>USA<br/>
$133.72 -0.85% 12/31/2020<br/>
Fundamentals--------------------------------<br/>
Market Cap      2256.08B<br/>
P/E             40.93<br/>
Forward P/E     30.83<br/>
P/S             8.22<br/>
PEG             3.24<br/>
P/FCF           38.06<br/>
Current Ratio   1.40<br/>
.....................<br/>
Earnings        Oct 29<br/>
Earning Surprise ++++++++++++<br/>
Last Rating:    12/16/20 Morgan Stanley Maintains Overweight 144.0<br/>
ETF/Weight:     XLK 24.90%<br/>
Valuations------------------------------------<br/>
DCF(Earn/FCF):  72.19/92.5<br/>
EV/EBITDA:      28.57<br/>
Rule-of-40%:    26.43%<br/>
GuruFocus:      $64.59<br/>
Yahoo:          Overvalued<br/>
Ratings-------------------------------------------<br/>
Strength:       6/10<br/>
Profitability:  9/10<br/>
Valuation:      1/10<br/>
Crammer:        12/22/2020,Buy,$131.88,<br/>
Stoxline:       3 stars<br/>
MotelyFool:     4 out of 5<br/>
TR Score:       10 Bullish:84% Sentiment:buy<br/>
PriceTarget:    $131.88|Buy|Hold|Sell:23|6|1<br/>
Technical & Trend ----------------------------------<br/>
Overall Trend:  Bullish (0.46)<br/>
Candle Stick:   Neutral Bearish Engulfing<br/>
Chart Signal:   Strong buy<br/>
News>Dec-29-20==================================================================================================<br/>
1   Heres How to Prepare Your Portfolio for the New Year, According to Charles Schwabs Liz Ann Sonders<br/>
2   Apple iPhones Take 9 of Top 10 Spots in Activations on Xmas Day<br/>
.................<br/>
What people say(social media)====================================================================================<br/>
TradingviewUser               LongShort YYYYMMDD  TradeWindow Reputation  #Ideas    #Likes    #Followers<br/>
TheSignalyst                  short     20201229  60          5917        625       7023      1554      <br/>
ch33zy                        long      20201230  240         25          82        104       42        <br/>
.................<br/>
Expert Name--------------Rating-Return%-YYYY-MM-DD-----URL---------------------------Title------------------<br/>
Will Ashworth              5    32.9    2020-12-30     https://tinyurl.com/yaocja5k  7 Music Stocks Ready to Party<br/>
Harsh Chauhan              5    23      2020-12-30     https://tinyurl.com/ybbvl4pt  Why Apple Could Be a Top Growth Stock in 2021<br/>
.................<br/>
SeekingAlpha-------------------------------------------------------------------------<br/>
https://tinyurl.com/yckhtm2u<br/>
What people do===================================================================================================<br/>
Fool Player-------------------Rating--MM/DD/YYYY--Time--StartPrice--URL---------------<br/>
phc19                         95.85   12/30/2020  5Y    $135.57     https://caps.fool.com/player/phc19.aspx<br/>
ebarrocas                     60.66   12/30/2020  5Y    $134.22     https://caps.fool.com/player/ebarrocas.aspx<br/>
.................<br/>
Buy/Short---Date------#Rank----MarketWatch Game---------------------------<br/>
Sell        12/30/20  48       https://tinyurl.com/yb2m229k<br/>
Buy         12/30/20  48       https://tinyurl.com/yb2m229k<br/>
ARK :Significant(>1%) change(+/-/0) in the fund in last 30 days----------------------------<br/>
ARKW:+00000<br/>
ARKQ:0++++0+0+00+++0+0+++0+00<br/>
ARKG:000000000<br/>
ARKF:0+++0++0+00++++++0+++0+0<br/>
Recent 13F filers by whaleswisdom-------------------------------------LastQ---LastY---<br/>
Add:AAPL  advisory-resource-group                                     26.21%  -6.72%  <br/>
Add:AAPL  bbk-capital-partners-llc                                    4.67%   4.63%   <br/>
.................<br/>
QQ-YYYY-13F filers by dataroma----------------------------------------Action----------<br/>
Q3 2020 Lee Ainslie - Maverick Capital                                Add 11300.00%  <br/>
Q3 2020 Thomas Russo - Gardner Russo & Gardner                        Add 11.15%     <br/>
...................

./
