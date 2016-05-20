class MarketReportController < ApplicationController
  def show
    data = ''
    report = MarketReport.new(data)
    output = report.to_pdf
    send_data output, filename: 'market_report.pdf', type: 'application/pdf'
  end
end
