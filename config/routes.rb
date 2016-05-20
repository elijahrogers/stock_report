Rails.application.routes.draw do
  resources :stock_report, controller: :single_stock_report, only: [:show]
  resource :market_report, controller: :market_report, only: [:show]
end
