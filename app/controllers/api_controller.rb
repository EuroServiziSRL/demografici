require 'httparty'
require 'uri'
require "base64"
require 'openssl'

class ApiController < ActionController::Base
  include ApplicationHelper
  # before_action :get_dominio_sessione_utente


  # richiesta da backoffice ente - autenticazione??
  def richiedi_prenotazioni
    # verifico autenticazione

    searchParams  = {}

    array_json = []

    if params[:tenant].nil?
      response["array_json"] << {
        "esito_richiesta": "003-Errore generico",
        "errore_descrizione": "è necessario specificare un tenant"
      }
    else
      searchParams[:tenant] = params[:tenant]
      searchParams[:stato] = "richiesto"
      if false
        # aggiungo parametri ricerca se necessario
        searchParams[:data_prenotazione] = params[:data]
      end
      # recupero da db
      richieste_certificati = Certificati.where("tenant = :tenant AND stato = :stato", searchParams)
  
      # compongo risposta
      richieste_certificati.each do |richiesta_certificato|
        array_json << {
          "tenant": richiesta_certificato.tenant,
          "codice_fiscale": richiesta_certificato.codice_fiscale,
          "codice_certificato": richiesta_certificato.codice_certificato, # ottenuti da compilazione form da parte del cittadino, questi verranno ottenuti da ws che restituisce elenco tipi certificato
          "bollo": richiesta_certificato.bollo, # ottenuti da compilazione form da parte del cittadino, sì/no
          "diritti_segreteria": richiesta_certificato.diritti_segreteria, # ottenuti da compilazione form da parte del cittadino, sì/no
          "uso": richiesta_certificato.uso, # ottenuti da compilazione form da parte del cittadino, probabilmente recuperati da ws?
          "richiedente_cf": richiesta_certificato.richiedente_cf,
          "richiesta": richiesta_certificato.richiesta
        }
      end
    end

    response = {
      "array_json": array_json
    }  

    # restituisco risposta
    response = response.to_json  
    render :json => response

    # tabella da fare richieste_prenotazioni
    # civiliaopen__timbroprenota e civiliaopen__timbrodettaglio

    # stato (vedi giugliano) data_inserimento e data_prenotazione e email
    # cf richiedente può essere anche id utente portale (vedi richiedente id timbroprenota), magari entrambi
    # id univoco
    # documento con percorso file
    # nome certificato

    # da tenere traccia di queste richieste
    # demografici_traccia (tabella già esistente in vecchia versione demografici)
    # scrivere su tabella db dell'ente (sta cosa è da fare anche per i cittadini. Ip chiamante, metodo chiamato, richiesta effettuata - anche ricerche)

    # response = {
    #   "array_json": [{
    #     "tenant": params[:tenant],
    #     "codice_fiscale": session[:cf],
    #     "codice_certificato": "xxxxx", # ottenuti da compilazione form da parte del cittadino, questi verranno ottenuti da ws che restituisce elenco tipi certificato
    #     "bollo": "1/0", # ottenuti da compilazione form da parte del cittadino, sì/no
    #     "diritti_segreteria": "1/0", # ottenuti da compilazione form da parte del cittadino, sì/no
    #     "uso": "descrizione", # ottenuti da compilazione form da parte del cittadino, probabilmente recuperati da ws?
    #     "richiedente_cf": session[:cf],
    #     "richiesta": "rujklnjkdosi"
    #   }]
    # }  
  end

  # richiesta da backoffice ente - autenticazione??
  def ricevi_certificato      
    # tenant
    # richiesta
    # esito_emissione (c'è sempre, se è 002 o 003 c'è anche errore descrizione, da salvare in tabella prenotazioni)
    # errore_descrizione (c'è solo se esito 002 o 003 - se 002 non emettibile annullare certificato, tutto asincrono! da salvare in tabella prenotazioni)
    # certificato (b64, si riconverte e poi si salva. Dove? in cartella dove lo posso comunque mostrare al cittadino)
    # aggiorno data_inserimento e stato (da pagare se bollo o segreteria, passare a pagamenti, come per caricamento pratiche/tributi con sha chiamata pagamenti)
    # 
    render plain: "OK"
  end

end