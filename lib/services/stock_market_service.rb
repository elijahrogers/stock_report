module Services

  class StockMarketService

    def self.by_ticker(sym)
      request = Typhoeus::Request.new("http://finance.yahoo.com/d/quotes.csv?s=#{sym}")
    end
  end

end
