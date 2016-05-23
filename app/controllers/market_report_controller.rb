class MarketReportController < ApplicationController
  def show
    data = ''
    report = MarketReport.new(data)
    output = report.render
    send_data output, filename: 'market_report.pdf', type: 'application/pdf'
  end
end
