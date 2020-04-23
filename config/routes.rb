Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index
  get '/richiedi_prenotazioni' => 'application#richiedi_prenotazioni', :as => :richiedi_prenotazioni
  get '/ricevi_certificato' => 'application#ricevi_certificato', :as => :ricevi_certificato

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto
  root to: "application#index"
end