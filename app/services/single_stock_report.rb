require 'prawn'
require 'prawn/icon'
require 'combine_pdf'
require 'gruff'
require 'stringio'
require 'open-uri'
require 'csv'
require 'yahoo-finance'
require "rss"

class SingleStockReport < Prawn::Document
  include Common::IncludeFont
  include Common::CombinePdf
  include Common::ColorTheme

  def initialize(ticker_sym)
    super()
    @template = "#{Rails.root}/app/pdf_templates/blank_pdf.pdf"
    @page_num = 1
    @ticker = ticker_sym
    yahoo_client = YahooFinance::Client.new
    @data = yahoo_client.quotes(["#{@ticker}"], [:name, :ask, :bid, :last_trade_price, :open, :close, :pe_ratio, :earnings_per_share, :average_daily_volume, :volume, :change, :high_52_weeks, :low_52_weeks, :moving_average_200_day,
     :moving_average_50_day, :market_capitalization, :price_per_book, :price_per_sales, :dividend_yield ])
    @graph_data = yahoo_client.historical_quotes("#{@ticker}", { start_date: Time::now-(24*60*60*10), end_date: Time::now })
  end

  def init_pdf
    add_font_code_light
    draw_first_page
  end

  def draw_first_page
    add_title
    add_stock_info
    add_year_range
    add_volume_indicator
    add_graph
    add_headlines
    stroke_axis
  end


  def add_stock_info
    move_down 10
    bounding_box([0,675], :character_spacing => 0.5, :overflow => :shrink_to_fit) do
      font_size 50
      text_box "$#{@data[0].last_trade_price.to_f.round(2)}", :align => :center, :width => 160, :height => 75, :overflow => :shrink_to_fit, :at => [20,675], :character_spacing => 0.5
      font_size 12
      text_box "B\ni\nd", :align => :center, :width => 20, :height => 45, :overflow => :shrink_to_fit, :at => [0, 685], :character_spacing => 0.5
      text_box "A\ns\nk", :align => :center, :width => 20, :height => 45, :overflow => :shrink_to_fit, :at => [180, 685], :character_spacing => 0.5
    end
      # font_size 50
      # text_box "$#{@data[0].last_trade_price.to_f.round(2)}", :align => :center, :width => 160, :height => 75, :overflow => :shrink_to_fit, :at => [20,675], :character_spacing => 0.5
      # font_size 12
      # text_box "B\ni\nd", :align => :center, :width => 20, :height => 45, :overflow => :shrink_to_fit, :at => [0, 685], :character_spacing => 0.5
      # text_box "A\ns\nk", :align => :center, :width => 20, :height => 45, :overflow => :shrink_to_fit, :at => [180, 685], :character_spacing => 0.5
      font_size 20
      bounding_box([0, 630], :width => 200, :height => 20) do
        text_box "#{@data[0].bid.to_f.round(2)}", :align => :left
        bounding_box([80,630], :width => 25) do
          if @data[0].change.to_f > 0
            self.icon 'fa-chevron-up', size: 15
          else
            self.icon 'fa-chevron-down', size: 15
          end
        end
        text_box "#{@data[0].change.to_f.abs}", :align => :center
        text_box "#{@data[0].ask.to_f.round(2)}", :align => :right
      end
    bounding_box([220, 675], :width => 165, :character_spacing => 0.5, :align => :center) do
      font_size 15
      text "Mkt Cap: $ #{@data[0].market_capitalization}"
      text "Open: $ #{@data[0].open.to_f.round(2)}"
      text "Close: $ #{@data[0].close.to_f.round(2)}"
      text "PE: #{@data[0].pe_ratio.to_f.round(1)}"
      stroke_bounds
    end
    bounding_box([385, 675], :width => 165, :character_spacing => 0.5, :align => :center) do
      text "Price Book: $ #{@data[0].price_per_book}"
      text "Price Sales: $ #{@data[0].price_per_sales}"
      text "EPS: $ #{@data[0].earnings_per_share.to_f.round(2)}"
      text "Div. Yield: $ #{@data[0].dividend_yield}"
      stroke_bounds
    end
  end

  def add_title
    font "Code_Light"
    string = "#{Time.now.strftime("%b %d %l:%M %Z")}"
    options = { :at => [bounds.right - 150, 740],
                :width => 150,
                :align => :right,
                :character_spacing => 0.5
              }
    number_pages string, options
    bounding_box([-35,725], :width => 610, :height => 20) do
      font "Code_Light"
      font_size 18
      text "Stock Report: #{@data[0].name}", :align => :center, :character_spacing => 0.5
    end
    move_down 10
    stroke_color "#56f649"
    stroke_horizontal_rule
  end

  def add_year_range
    font_size 12
    text_box "52 Week Range", :at => [200, 465], :height => 20, :width => 100, :align => :center, :character_spacing => 0.5
    high = @data[0].high_52_weeks.to_f.round(2)
    low = @data[0].low_52_weeks.to_f.round(2)
    range = high - low
    pos = ((@data[0].last_trade_price.to_f.round(2) - low) / range) * 350
    stroke_color "#000000"
    stroke do
    horizontal_line 100, 450, :at => 500
    vertical_line 495, 505, :at => pos + 100
    end
    font_size 10
    text_box "#{low}", :at => [0, 505], :height => 20, :width => 90, :align => :right, :character_spacing => 0.5
    text_box "#{high}", :at => [460, 505], :height => 20, :width => 90, :align => :left, :character_spacing => 0.5
    text_box "#{@data[0].last_trade_price.to_f.round(2)}", :at => [(pos + 90), 490], :height => 20, :width => 30, :align => :center, :character_spacing => 0.5
  end

  def add_volume_indicator
    vol = @data[0].volume.to_f
    avg_vol = @data[0].average_daily_volume.to_f
    pos = ((vol - avg_vol)/ avg_vol) * 100.00
    if pos < 0
      fill_color "#00ff4f"
    elsif pos > 0
      fill_color "#ff0000"
    end
    fill_rectangle [20, 300 + pos ], 100, pos
    stroke_color "#000000"
    stroke do
      horizontal_line 10, 130, :at => 300
      vertical_line 200, 400, :at => 10
      horizontal_line 5, 15, :at => 400
      horizontal_line 5, 15, :at => 200
    end
    font_size 8
    text_box "Avg. Vol", :at => [140, 310], :height => 20, :width => 35, :align => :center, :character_spacing => 0.5,:color => "#494949"
    font "Helvetica"
    font_size 6
    text_box "100%", :at => [-20, 405], :height => 20, :width => 20, :align => :center, :character_spacing => 0.5, :color => "#00FF4F"
    text_box "-100%", :at => [-20, 205], :height => 20, :width => 20, :align => :center, :character_spacing => 0.5, :color => "#ff0000"
  end

  def add_graph
    font "Helvetica"
    graph = Gruff::Line.new('1200x800')
    open = []
    close = []
    @graph_data.each_with_index do |d, index|
      open << (d[:open]).to_f
      close << (d[:close]).to_f
      graph.labels[index] = (d[:trade_date]).slice(5..9).gsub(/-/, ' ')
    end
    moving_avg_50 = Array.new(@graph_data.count){ |i| i = @data[0].moving_average_50_day.to_f }
    moving_avg_200 = Array.new(@graph_data.count){ |i| i = @data[0].moving_average_200_day.to_f }
    graph.data '50 Day Moving Average', moving_avg_50
    graph.data '200 Day Moving Average', moving_avg_200
    graph.data 'Open', open
    graph.data 'Close', close
    graph.title = "#{@data[0].name}"
    graph.theme = gruff_theme
    graph.hide_dots = true
    graph.hide_title = true
    graph.font = "#{Rails.root}/public/fonts/Hero.ttf"
    chart = StringIO.new(graph.to_blob)
    image chart, scale: 0.30, at: [190, 400]
  end

  def add_headlines
    url = "https://feeds.finance.yahoo.com/rss/2.0/headline?s=#{@ticker}&region=US&lang=en-US"
    headlines =[]
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        headlines << item.title
      end
    end
    text_box "Headlines", :at => [0,100], :height => 100, :width => 550, :align => :center
    horizontal_line 225, 325, :at => 95
    pos = 90
    headlines.each do |headline|
      text_box headline, :at => [0, pos], :height => 10, :width => 550, :align => :center
      pos -= 10
    end
  end

  def add_arrow(change,x,y)
    bounding_box([x,y], :width => 20) do
      if change > 0
        self.icon 'fa-chevron-up', size: 10, :color => "#17FF00"
      else
        self.icon 'fa-chevron-down', size: 10, :color => "#FF0000"
      end
    end
  end

end
