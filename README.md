# Stock Report

This is a dynamic PDF generator utilizing Blake Campbell's [dynamic_pdfs](https://github.com/BlakeCampbells/dynamic_pdfs)

## Setup

* This repo requires [Ruby](https://www.ruby-lang.org/en/downloads/) to be installed locally
* Pull repo and install the required gems using `bundle install`
* Run rails server locally on port 3000 using `rails server`
* Hit a valid route to generate a PDF

## Valid Routes

* http://localhost:3000/stock_report/AAPL
  * Any ticker can be used
  * Tickers can be found at [Yahoo! Finance](http://finance.yahoo.com/lookup)
  * Multiple comma seperated tickers may be used to get reports for multiple companies in a single PDF
    * Example: http://localhost:3000/stock_report/AAPL,GOOG,FB
* http://localhost:3000/market_report
