class SingleStockReportController < ApplicationController
  def show
    data = ''
    ticker_sym = params[:id] || "AAPL"
    report = SingleStockReport.new(ticker_sym)
    output = report.render
    send_data output, filename: 'stock_report.pdf', type: 'application/pdf'
  end
end
