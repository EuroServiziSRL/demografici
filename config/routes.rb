Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index
  get '/api/richiedi_prenotazioni' => 'api#richiedi_prenotazioni', :as => :richiedi_prenotazioni
  get '/api/ricevi_certificato' => 'api#ricevi_certificato', :as => :ricevi_certificato

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto
  root to: "application#index"
end