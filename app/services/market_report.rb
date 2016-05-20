require 'prawn'
require 'prawn/icon'
require 'combine_pdf'
require 'gruff'
require 'stringio'
require 'open-uri'

class MarketReport < Prawn::Document
  include Common::IncludeFont
  include Common::CombinePdf
  include Common::ColorTheme

  def initialize(_data)
    super()
    @template = "#{Rails.root}/app/pdf_templates/blank_pdf.pdf"
    @page_num = 1
    yahoo_client = YahooFinance::Client.new
    @data = yahoo_client.quotes(["IYY","^GSPC","^IXIC","EURUSD=X","USDJPY=X","GBPUSD=X","USDCHF=X","^IRX","^FVX","^TNX","^TYX", "CLN16.NYM", "NGM16.NYM", "GCM16.CMX", "GC.CMX", "SI.CMX", "CN16.CBT", "KCK16.NYB"], [:name, :last_trade_price, :open, :close, :average_daily_volume, :volume, :change, :high_52_weeks, :low_52_weeks])
    @commodities_data = yahoo_client.quotes(["CLN16.NYM", "NGM16.NYM", "GCM16.CMX", "SI.CMX","HG.CMX", "CN16.CBT", "ON16.CBT", "KCK16.NYB", "CTN16.NYB", "SBN16.NYB"], [:name, :last_trade_price, :change])
    @dow_data = yahoo_client.historical_quotes( "IYY", { start_date: Time::now-(24*60*60*13), end_date: Time::now })
    @sp_data = yahoo_client.historical_quotes( "^GSPC", { start_date: Time::now-(24*60*60*13), end_date: Time::now })
    @nasdaq_data = yahoo_client.historical_quotes( "^IXIC", { start_date: Time::now-(24*60*60*13), end_date: Time::now })
  end

  private

  def init_pdf
    add_font_code_light
    draw_first_page
  end

  def draw_first_page
    convert_dow
    add_title
    add_indices_info
    add_year_range
    add_graph
    add_currencies
    add_t_bonds
    add_commodities
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
      text "Market Report: #{Time.now.strftime("%b %d, %Y")}", :align => :center, :character_spacing => 0.5
    end
    move_down 10
    stroke_color "#56f649"
    stroke_horizontal_rule
  end

  def add_indices_info
    font_size 12
    font "Code_Light"
    @indices = ["DOW", "S&P 500", "Nasdaq"]
    pos = 675
    for i in 0..2
      text_box @indices[i], :at => [0, pos], :height => 20, :width => 55, :align => :left, :character_spacing => 0.5, :overflow => :shrink_to_fit
      text_box "$ #{@data[i].last_trade_price}", :at => [55, pos], :height => 20, :width => 70, :align => :right, :character_spacing => 0.5, :overflow => :shrink_to_fit
      add_arrow(@data[i].change.to_f, 180, pos)
      text_box "#{@data[i].change.to_f.abs}", :at => [200, pos], :height => 20, :width => 70, :align => :left, :character_spacing => 0.5, :overflow => :shrink_to_fit
      pos -= 25
    end
  end

  def add_year_range
    font_size 8
    text_box "52 Week Range", :at => [400, 690], :height => 15, :width => 80, :align => :center
    line_pos = 670
    for i in 0..2
    high = @data[i].high_52_weeks.to_f.round(2)
    low = @data[i].low_52_weeks.to_f.round(2)
    range = high - low
    pos = ((@data[i].last_trade_price.to_f.round(2) - low) / range) * 150
    stroke_color "#000000"
      stroke do
      horizontal_line 350, 500, :at => line_pos
      vertical_line line_pos - 5, line_pos + 5, :at => pos + 350
      end
    text_box "#{low.to_i}", :at => [300, line_pos + 5], :height => 20, :width => 45, :align => :right, :character_spacing => 0.5
    text_box "#{high.to_i}", :at => [505, line_pos + 5], :height => 20, :width => 50, :align => :left, :character_spacing => 0.5
    text_box "#{@data[i].last_trade_price.to_i}", :at => [(pos + 335), line_pos - 10], :height => 20, :width => 30, :align => :center, :character_spacing => 0.5
    line_pos -= 25
    end
  end

  def convert_dow
    symbols = [:last_trade_price, :change, :low_52_weeks, :high_52_weeks, :volume, :average_daily_volume]
    symbols.each do |sym|
      @data[0][sym] = (@data[0][sym].to_f * 175).round(2).to_s
    end
  end

  def add_graph
    graph = Gruff::Line.new('1200x600')
    dow = []
    sp = []
    nasdaq = []
    @dow_data.reverse.each do |date|
      dow << ((date[:close].to_f - date[:open].to_f) / date[:open].to_f) * 100
    end
    @sp_data.reverse.each_with_index do |date, index|
      sp << ((date[:close].to_f - date[:open].to_f) / date[:open].to_f) * 100
      graph.labels[index] = (date[:trade_date]).slice(5..9).gsub(/-/, ' ')
    end
    @nasdaq_data.reverse.each do |date|
      nasdaq << ((date[:close].to_f - date[:open].to_f) / date[:open].to_f) * 100
    end
    all_values = nasdaq + sp + dow
    graph.data "DOW", dow
    graph.data "S&P 500", sp
    graph.data "Nasdaq", nasdaq
    graph.title = " "
    graph.theme = gruff_theme
    graph.hide_dots = true
    graph.y_axis_increment = 0.5
    graph.minimum_value = all_values.min.floor
    graph.hide_title = true
    graph.font = "#{Rails.root}/public/fonts/Hero.ttf"
    chart = StringIO.new(graph.to_blob)
    image chart, scale: 0.40, at: [50, 575]
  end

  def add_currencies
    font_size 12
    text_box "FOREX", :at => [0, 300], :height => 20, :width => 275, :align => :center
    stroke_horizontal_line 10, 265, :at => 285
    pos = 275
    for i in 3..6
      text_box @data[i].name.gsub("/", ' '), :at => [10, pos], :height => 20, :width => 85, :align => :left, :character_spacing => 0.5
      add_arrow(@data[i].change.to_f, 125, pos)
      text_box @data[i].change.to_f.abs.to_s, :at => [125, pos], :height => 20, :width => 65, :align => :right, :character_spacing => 0.5
      text_box @data[i].last_trade_price, :at => [190, pos], :height => 20, :width => 75, :align => :right, :character_spacing => 0.5
      pos -= 20
    end
    font "Helvetica"
  end

  def add_t_bonds
    font "Code_Light"
    text_box "US Treasury Bond Yields", :at => [0, 175], :height => 20, :width => 275, :align => :center
    stroke_horizontal_line 10, 265, :at => 160
    pos = 150
    bond = ["3 M", "5 Yr", "10 Yr", "30 Yr"]
    for i in 7..10
      text_box bond[i - 7], :at => [10, pos], :height => 20, :width => 85, :align => :left, :character_spacing => 0.5
      add_arrow(@data[i].change.to_f, 125, pos)
      text_box @data[i].change.to_f.abs.to_s, :at => [125, pos], :height => 20, :width => 65, :align => :right, :character_spacing => 0.5
      text_box "#{@data[i].last_trade_price}", :at => [190, pos], :height => 20, :width => 75, :align => :right, :character_spacing => 0.5
      pos -= 20
    end
  end

  def add_commodities
    text_box "Commodities", :at => [275, 300], :height => 20, :width => 275, :align => :center
    stroke_horizontal_line 285, 540, :at => 285
    commodities = ["Crude Oil", "Natural Gas", "Gold", "Silver", "Copper", "Corn", "Oats", "Coffee", "Cotton", "Sugar"]
    pos = 275
    for i in 0..9
      text_box commodities[i], :at => [285, pos], :height => 20, :width => 85, :align => :left, :character_spacing => 0.5
      add_arrow(@commodities_data[i].change.to_f, 370, pos)
      text_box @commodities_data[i].change.to_f.abs.to_s, :at => [390, pos], :height => 20, :width => 65, :align => :right, :character_spacing => 0.5
      text_box @commodities_data[i].last_trade_price, :at => [455, pos], :height => 20, :width => 80, :align => :right, :character_spacing => 0.5
      pos -= 20
    end
  end

  def add_arrow(change,x,y)
    bounding_box([x,y], :width => 20) do
      if change > 0
        self.icon 'fa-chevron-up', size: 10, :color => "#17FF00"
      else
        self.icon 'fa-chevron-down', size: 10, :color => "FF0000"
      end
    end
  end

end
