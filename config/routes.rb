Rails.application.routes.draw do
  get '/' => 'application#index', :as => :index
  get '/dettagli_persona' => 'application#dettagli_persona', :as => :dettagli_persona
  get '/scarica_certificato' => 'application#scarica_certificato', :as => :scarica_certificato
  post '/richiedi_certificato' => 'application#richiedi_certificato', :as => :richiedi_certificato
  # get '/ricerca_anagrafiche' => 'application#ricerca_anagrafiche', :as => :ricerca_anagrafiche
  # post '/ricerca_anagrafiche' => 'application#ricerca_anagrafiche', :as => :ricerca_anagrafiche
  match '/ricerca_anagrafiche' => 'application#ricerca_anagrafiche', via: [:get, :post]
  get '/ricerca_anagrafiche_individui' => 'application#ricerca_anagrafiche_individui', :as => :ricerca_anagrafiche_individui
  get '/authenticate' => 'application#authenticate', :as => :authenticate
  get '/ricerca_individui' => 'application#ricerca_individui', :as => :ricerca_individui
  post '/api/richiedi_prenotazioni' => 'api#richiedi_prenotazioni', :as => :richiedi_prenotazioni
  post '/api/ricevi_certificato' => 'api#ricevi_certificato', :as => :ricevi_certificato
  get '/api/genera_prenotazioni_test' => 'api#genera_prenotazioni_test', :as => :genera_prenotazioni_test

  get 'error_dati' => "application#error_dati", :as => :error_dati

  get 'sconosciuto' => 'application#sconosciuto', :as => :sconosciuto

  get 'logout' => 'application#logout', :as => :logout

  root to: "application#index"
end