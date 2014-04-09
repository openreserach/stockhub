stockhub
========

stockhub is a suite scripts that crawls investment web sites to fetch top performers' recent buy/sell transactions/ portfolios, and presents trading idea in seconds. The rationales of the tool is simply as follows: 
in 1~2 day, if a stock is bought/sold independently by multiple top performers with good track records (e.g., in term of annual return)it is more than likely to be a good idea again, at least better than a clueless amateur who under-performs market. 

If you are investment guru, no bother. If you are like me, picking "persons" than picking stocks within limited time window, this is a tool for you.

The project is named stockhub because it is a hub of collective wisdom. The tool sources data from Internet investment sites, ranging from published portfolios of professional or grass-root investors, to more casual stock trading competition postings. Some trading records are varifi-able by 3-rd parties, while others can only be cross-referenced by historical performances provided by each system.

No single record is absolutely reliable, but collectively, it provide a "crowds intelligence". Here is a sample output:

The tool is implemented by light-weighted shell scripts. You can run it on any Linux or Windows (e.g., on top of cygwin) even behind firewall. See a sample output at the bottom.

Disclaimer: Totally for fun. 
==================================================================================================================

$ ./rating.sh AAPL
AAPL:530.22 +(1.30%) 04/09/2014
Apple Inc.
Consumer Goods >Electronic Equipment >USA
FA color-coded==============================
Market Cap:             466.90B
P/E:            12.98
Forward P/E:            11.25
P/C:            11.47
P/FCF:          13.98
P/B:            3.62
Debt/Eq:                0.13
Current Ratio:          1.50
ROA:            17.90%
ROE:            28.90%
EPS next 5Y:            21.28%
Dividend %:             2.33%
================================
Predictability:  4.5
MSN Rating:     7
Crammer:        04/02/2014 S 542.55
50MA vs. S&P:   -0.55 vs. +0.31
Stoxline:       3 stars
Motely(0-5):    3
Trend Spotter:  Sell
Stockpickr:     B+
GuruFairValue:   $712.39
USBull Signal    STAY IN CASH
USBull Pattern   NO PATTERN
Covestor Top Manager Recent Transactions==================
Stock      Action     Price      Date       Trade/Mon  Return     Manager                        Portfolio
AAPL       Buy        $549.61    01/27/14   8.0        -1.2%      leif-eriksen                   pwp-growth-and-income
AAPL       Buy        $535.80    02/19/14   1.0        -5.4%      marketocracy                   core-portfolio
AAPL       Buy        $524.87    10/23/13   1.3        1.5%       brendan-ruchert-dixon          beta-blocker
AAPL       Buy        $501.09    08/16/13   1.3        1.5%       brendan-ruchert-dixon          beta-blocker
AAPL       Buy        $402.05    04/17/13   1.3        1.5%       brendan-ruchert-dixon          beta-blocker
AAPL       Buy        $560.81    12/03/13   3.5        2.3%       brendan-ruchert-dixon          alpha-trapper
AAPL       Sellshort  $524.05    10/23/13   3.5        2.3%       brendan-ruchert-dixon          alpha-trapper
AAPL       Sell       $500.20    08/15/13   3.5        2.3%       brendan-ruchert-dixon          alpha-trapper
Covestor Top Manager Current Holdings=====================
Manager                                 Portfolio                                   Sharp%      Gain LongShort     Price
bsgl                                    pure-growth                                   0.86      14.5
bsgl                                    growth-plus-income                            0.91      10.3
harvest-fp                              domestic-dividend                             1.79      12.4
libardo-lambrano                        dividend-paying-large-caps                    2.20      24.6
marketocracy                            core-portfolio                                1.19      13.7       Buy   $535.80
TheLion Top Manager Recent Transactions===================
User            Stock Status     Action  Buydate    Selldate   Buyprice   Sellprice  Gain%
BZLitorale      AAPL  Active     Buy     01/13/2014 ---        535.73     ---        ---
ch90            AAPL  Active     Short   09/09/2009 ---        171.14     ---        ---
sarushi         AAPL  Active     Buy     10/23/2012 ---        613.36     ---        ---
sarushi         AAPL  Closed     Buy     06/01/2012 06/19/2012 560.99     588.16     4.84%
theMagician     AAPL  Active     Buy     01/18/2013 ---        500.00     ---        ---
XSCOM           AAPL  Closed     Buy     01/17/2013 04/23/2013 502.68     400.08     -20.41%
MarketWatch Practice-stock-for-fun game Top players Recent Transactions===================
Player                         Rank  Stock      Date       Action     Shares     Price
Joshua-Kaufman                 37    AAPL       3/17/14    Buy        192        $528.85
guille-rdguez                  68    AAPL       4/9/14     Sell       223        $526.54
guille-rdguez                  68    AAPL       4/8/14     Buy        223        $524.59
Birol-Arslan                   77    AAPL       3/3/14     Sell       29         $523.02
MarketWatch RedditChallenge2014 game Top players Recent Transactions===================
Player                         Rank  Stock      Date       Action     Shares     Price
Matt-Ruhland                   75    AAPL       3/20/14    Sell       100        $531.99
alan-hu                        81    AAPL       3/3/14     Cover      100        $523.81
MarketWatch DaQian-1 game Top players Recent Transactions===================
Player                         Rank  Stock      Date       Action     Shares     Price
Jerry-Wang                     30    AAPL       3/3/14     Buy        100        $523.63
amanda-Dillon                  51    AAPL       3/24/14    Buy        100        $535.50
Radar Screen----------------------------------------
Graham Intrinsic Value
SeekingAlphaLongIdea
SeekingAlphaShortIdea
DaQianLongIdea
MarketocracyTopHolding

