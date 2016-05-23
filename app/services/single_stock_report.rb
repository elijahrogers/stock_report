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
    @ticker = ticker_sym.upcase
    yahoo_client = YahooFinance::Client.new
    @data = yahoo_client.quotes(["#{@ticker}"], [:name, :ask, :bid, :last_trade_price, :open, :close, :pe_ratio, :earnings_per_share, :average_daily_volume, :volume, :change, :high_52_weeks, :low_52_weeks, :moving_average_200_day,
     :moving_average_50_day, :market_capitalization, :price_per_book, :price_per_sales, :dividend_yield ])
    @graph_data = yahoo_client.historical_quotes("#{@ticker}", { start_date: Time::now-(24*60*60*10), end_date: Time::now })
    init_pdf
  end

  def init_pdf
    add_font_code_light
    add_font_awesome
    draw_first_page
  end

  def draw_first_page
    add_title
    add_stock_info
    add_stats
    add_year_range
    add_volume_indicator
    add_headlines
    add_graph
  end

  def add_stock_info
    bounding_box([0,675], :character_spacing => 0.5, :width => 200, :height => 65) do
      bounding_box([0, bounds.top], :width => 20) do
        text_box "B\ni\nd", :overflow => :shrink_to_fit, :size => 15
      end
      bounding_box([175, bounds.top], :width => 25, :overflow => :shrink_to_fit) do
        text_box "A\ns\nk", :overflow => :shrink_to_fit, :size => 15
      end
      bounding_box([25, bounds.top], :width => 140 ) do
        text_box "$#{@data[0].last_trade_price.to_f.round(2)}", :overflow => :shrink_to_fit, :size => 70
      end
    end
    font_size 20
    bounding_box([0, 610], :width => 200, :height => 20) do
      text_box "#{@data[0].bid.to_f.round(2)}", :at => [0, bounds.top], :with => 60, :overflow => :shrink_to_fit
      add_arrow
      text_box "#{@data[0].change.to_f.abs}", :at => [90, bounds.top], :width => 50, :overflow => :shrink_to_fit
      text_box "#{@data[0].ask.to_f.round(2)}", :at => [140, bounds.top], :width => 60, :overflow => :shrink_to_fit
    end
  end

  def add_stats
    bounding_box([220, 670], :width => 165, :character_spacing => 0.5, :align => :center) do
      font_size 15
      text "Mkt Cap: $ #{@data[0].market_capitalization}"
      text "Open: $ #{@data[0].open.to_f.round(2)}"
      text "Close: $ #{@data[0].close.to_f.round(2)}"
      text "PE: #{@data[0].pe_ratio.to_f.round(1)}"
    end
    bounding_box([385, 670], :width => 165, :character_spacing => 0.5, :align => :center) do
      text "Price Book: $ #{@data[0].price_per_book}"
      text "Price Sales: $ #{@data[0].price_per_sales}"
      text "EPS: $ #{@data[0].earnings_per_share.to_f.round(2)}"
      text "Div. Yield: $ #{@data[0].dividend_yield}"
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
      text "Stock Report: #{@data[0].name}", :align => :center, :character_spacing => 0.5, :size => 18
    end
    move_down 10
    stroke_color "56F649"
    stroke_horizontal_rule
  end

  def add_year_range
    bounding_box([100, 350], :width => 350) do
      text_box "52 Week Range", :align => :center, :character_spacing => 0.5, :size => 12
      high = @data[0].high_52_weeks.to_f.round(2)
      low = @data[0].low_52_weeks.to_f.round(2)
      range = high - low
      pos = ((@data[0].last_trade_price.to_f.round(2) - low) / range) * 250
      stroke_color "000000"
      stroke do
        horizontal_line 50, 300, :at => bounds.top - 45
        vertical_line bounds.top - 50, bounds.top - 40, :at => pos + 50
      end
      font_size 10
      text_box "#{low}", :at => [0, bounds.top - 40 ], :height => 20, :width => 45, :align => :right, :character_spacing => 0.5, :overflow => :shrink_to_fit
      text_box "#{high}", :at => [305, bounds.top - 40], :height => 20, :width => 45, :align => :left, :character_spacing => 0.5, :overflow => :shrink_to_fit
      text_box "#{@data[0].last_trade_price.to_f.round(2)}", :at => [(pos + 40), bounds.top - 55], :height => 20, :width => 30, :align => :center, :character_spacing => 0.5
    end
  end

  def add_volume_indicator
    bounding_box([0, 550], :width => 180) do
      vol = @data[0].volume.to_f
      avg_vol = @data[0].average_daily_volume.to_f
      pos = ((vol - avg_vol)/ avg_vol) * 100.00
      if pos > 0
        fill_color "00FF4F"
      else
        fill_color "FF0000"
      end
      fill_rectangle [35, (bounds.top - 100) + pos ], 100, pos
      fill_color "000000"
      stroke do
        horizontal_line 30, 150, :at => bounds.top - 100
        vertical_line bounds.bottom, bounds.top, :at => 10
        i = 0
        while i <= 200
          horizontal_line 20, 30, :at => bounds.top - i
          i += 25
        end
      end
      text_box "Avg. Vol", :at => [160, bounds.top - 95], :height => 20, :width => 35, :align => :center, :character_spacing => 0.5, :size => 8
      font "Helvetica"
      font_size 6
      text_box "100%", :at => [0, bounds.top ], :height => 20, :width => 20, :align => :center, :character_spacing => 0.5, :color => "00FF4F"
      text_box "-100%", :at => [0, bounds.top - 195], :height => 10, :width => 20, :align => :center, :character_spacing => 0.5, :color => "FF0000"
    end
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
    image chart, scale: 0.30, at: [90, 250]
  end

  def add_headlines
    url = "https://feeds.finance.yahoo.com/rss/2.0/headline?s=#{@ticker}&region=US&lang=en-US"
    headlines =[]
    links = []
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        headlines << item.title
        links << item.link.split('*').pop
      end
    end
    bounding_box([230, 550], :width => 300) do
      font_size 12
      stroke_color "000000"
      font "Code_Light"
      text_box "Headlines", :at => [100, bounds.top], :height => 20, :width => 100, :align => :center
      stroke_horizontal_line 0, 300, :at => bounds.top - 20
      pos = bounds.top - 25
      headlines.first(8).each_with_index do |headline, index|
        text_box headline.gsub(/-/, ' '), :at => [20, pos], :height => 10, :width => 300, :align => :left, :overflow => :shrink_to_fit, :color => "000000"
        font "fa"
        text_box %(<link href="#{links[index]}"></link>), :inline_format => true, :height => 10, :width => 20, :at => [0, pos], :inline_format => true, :character_spacing => 0.5, :overflow => :shrink_to_fit
        pos -= 15
        font "Code_Light"
      end
    end
  end

  def add_arrow
    bounding_box([65, bounds.top], :width => 25) do
      if @data[0].change.to_f > 0
        self.icon 'fa-chevron-up', size: 15, :color => "30FF00"
      else
        self.icon 'fa-chevron-down', size: 15, :color => "FF0000"
      end
    end
  end

end
