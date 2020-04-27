Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index
  post '/api/richiedi_prenotazioni' => 'api#richiedi_prenotazioni', :as => :richiedi_prenotazioni
  post '/api/ricevi_certificato' => 'api#ricevi_certificato', :as => :ricevi_certificato
  get '/api/genera_prenotazioni_test' => 'api#genera_prenotazioni_test', :as => :genera_prenotazioni_test

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto
  root to: "application#index"
end