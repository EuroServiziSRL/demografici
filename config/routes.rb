Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index
  get '/dettagli_persona' => 'application#dettagli_persona', :as => :dettagli_persona
  get '/scarica_certificato' => 'application#scarica_certificato', :as => :scarica_certificato
  post '/richiedi_certificato' => 'application#richiedi_certificato', :as => :richiedi_certificato
  get '/authenticate' => 'application#authenticate', :as => :authenticate
  get '/ricerca_individui' => 'application#ricerca_individui', :as => :ricerca_individui
  post '/api/richiedi_prenotazioni' => 'api#richiedi_prenotazioni', :as => :richiedi_prenotazioni
  post '/api/ricevi_certificato' => 'api#ricevi_certificato', :as => :ricevi_certificato
  get '/api/genera_prenotazioni_test' => 'api#genera_prenotazioni_test', :as => :genera_prenotazioni_test

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto
  root to: "application#index"
end