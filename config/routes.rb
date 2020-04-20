Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto
  root to: "application#index"
end
