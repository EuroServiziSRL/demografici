require 'httparty'
require 'uri'
require "base64"
require 'openssl'
require 'fileutils'

begin
  require 'jwt'
rescue LoadError => exc
  raise "Installare gemma jwt e usare ruby > 2"
end

class ApiController < ActionController::Base
  include ApplicationHelper
  skip_before_action :verify_authenticity_token
  # before_action :autentica_ente

  # creare db unico

  # richiesta certificato da utente cittadino - salvate in un db unico
  # api lato nostro (demografici) che va chiamata per inserire traccia richieste utente
  # oppure tabella nel db unico

  # per richieste da ente 
  # tabella unica prenotazioni + certificati

  # gli stati saranno:
  # nuovo -> Nuova richiesta pronta x essere inviata a CiviliaNext sarà accompagnato dalla data_prenotazione ovvero la data di richiesta del certificato da parte dell'utente
  # in_attesa -> In attesa di ricezione del certificato da parte di CiviliaNext o di eventuale errore
  # da_pagare -> quando arriva il documento verificare se è stato richiesto il certifcato in bollo e/o diritti di segreteria e se a setup saranno richiesti degli emolumenti (sarà da inviare la somma da pagare a Pagamenti)
  # pagato -> Quando non c'è una mail ovvero non è possibile inviare al cittadino il documento ma rimarrà presente nel suo cassetto delle prenotazioni
  # scaricato -> inviata email al cittadino con il certificato firmato digitalmente 
  # annullato -> quando si è verificato un errore durante la generazione del certificato da parte di CiviliaNext e non sarà possibile in alcun modo riprocessare la richiesta. Sarà da inviare una mail al cittadino (se presente) informandolo del problema e/o visualizzare la situazione nel cassetto delle prenotazioni. 

  # richiesta da backoffice ente
  def richiedi_prenotazioni
    autenticato = autentica_ente

    searchParams = {}

    prenotazioni = []
    esito = []

    if autenticato["esito"]=="ko"
      esito << {
        "codice_esito": "001-Errore di autenticazione",
        "errore_descrizione": autenticato["msg_errore"]
      }
    else
      if params[:tenant].nil?
        esito << {
          "codice_esito": "002-Dati mancanti",
          "errore_descrizione": "è necessario specificare un tenant"
        }
      else
        searchParams[:tenant] = params[:tenant]
        if !params[:stato].nil?
          searchParams[:stato] = params[:stato]
        else
          searchParams[:stato] = "nuovo"
        end
        # recupero da db
        if !params[:data].nil?
          searchParams[:data_prenotazione_start] = DateTime.parse(params[:data]+" 00:00:00")
          searchParams[:data_prenotazione_end] = DateTime.parse(params[:data]+" 23:59:59")
          
          richieste_certificati = Certificati.where("tenant = :tenant AND stato = :stato AND data_prenotazione >= :data_prenotazione_start AND data_prenotazione <= :data_prenotazione_end", searchParams)
        else
          richieste_certificati = Certificati.where("tenant = :tenant AND stato = :stato", searchParams)
        end
    
        # compongo risposta
        richieste_certificati.each do |richiesta_certificato|
          prenotazioni << {
            "tenant": richiesta_certificato.tenant,
            "codice_fiscale": richiesta_certificato.codice_fiscale,
            "codice_certificato": richiesta_certificato.codice_certificato, # ottenuti da compilazione form da parte del cittadino, questi verranno ottenuti da ws che restituisce elenco tipi certificato
            "bollo": richiesta_certificato.bollo, # ottenuti da compilazione form da parte del cittadino, sì/no
            "diritti_segreteria": richiesta_certificato.diritti_segreteria, # ottenuti da compilazione form da parte del cittadino, sì/no
            "uso": richiesta_certificato.uso, # ottenuti da compilazione form da parte del cittadino, probabilmente recuperati da ws?
            "richiedente_cf": richiesta_certificato.richiedente_cf,
            "richiesta": richiesta_certificato.id
          }
          if searchParams[:stato] == "nuovo"
            # aggiorno solo se stato ricercato == nuovo
            richiesta_certificato.stato = "in_attesa"
            richiesta_certificato.save
          end
        end
        esito << {
          "codice_esito": "000-Prenotazioni richieste"
        }

      end
    end

    response = {
      "esito": esito,
      "prenotazioni": prenotazioni
      # "received": params
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
  
  end

  # richiesta da backoffice ente
  def ricevi_certificato    
    autenticato = autentica_ente

    # tenant
    # richiesta
    # esito_emissione (c'è sempre, se è 002 o 003 c'è anche errore descrizione, da salvare in tabella prenotazioni)
    # errore_descrizione (c'è solo se esito 002 o 003 - se 002 non emettibile annullare certificato, tutto asincrono! da salvare in tabella prenotazioni)
    # certificato (b64, si riconverte e poi si salva. Dove? in cartella dove lo posso comunque mostrare al cittadino)
    # aggiorno data_inserimento e stato (da pagare se bollo o segreteria, passare a pagamenti, come per caricamento pratiche/tributi con sha chiamata pagamenti)
    # 
    searchParams = {}

    array_json = []

    if false && autenticato["esito"]=="ko"
      array_json << {
        "codice_esito": "001-Errore di autenticazione",
        "errore_descrizione": autenticato["msg_errore"]
      }
    else
      if params[:tenant].nil?
        array_json << {
          "codice_esito": "002-Dati mancanti",
          "errore_descrizione": "è necessario specificare un tenant"
        }
      elsif params[:richiesta].nil?
        array_json << {
          "codice_esito": "002-Dati mancanti",
          "errore_descrizione": "è necessario specificare una richiesta"
        }    
      elsif params[:certificato].nil?
        array_json << {
          "codice_esito": "002-Dati mancanti",
          "errore_descrizione": "il certificato non può essere vuoto"
        }
      else
        searchParams[:id] = params[:richiesta]
        searchParams[:stato] = "richiesto"
        richiesta_certificato = Certificati.find(params[:richiesta])
  
        if richiesta_certificato.blank?
          array_json << {
            "codice_esito": "003-Errore generico",
            "errore_descrizione": "richiesta non trovata"
          }
        elsif richiesta_certificato.documento.present?
          array_json << {
            "codice_esito": "004-Certificato presente"
          }
        else
          basedir = createPath( [params[:tenant], Time.now.year.to_s, Time.now.month.to_s] )
          puts basedir

          # creo file 
          path = File.join(basedir, richiesta_certificato.codice_certificato[/^([0-9]{1,2})/,1]+"_"+richiesta_certificato.codice_fiscale+".pdf")
          File.open(path, "wb") { |f| f.write(Base64.decode64(params[:certificato])) }
          richiesta_certificato.documento = path
          richiesta_certificato.stato = "da_pagare"
          richiesta_certificato.data_inserimento = Time.now
          richiesta_certificato.save
          array_json << {
            "codice_esito": "000-Certificato inserito"
          }
        end
  
      end
    end

    response = {
      "esito": array_json
      # "received": params
    }  

    # restituisco risposta
    response = response.to_json  
    render :json => response
    # render plain: "OK"
  end

  def genera_prenotazioni_test
    array_json = []
    x = 0
    nomi_certificati = ['1 - Anagrafico di nascita', '2 - Anagrafico di morte', '3 - Anagrafico di matrimonio', '4 - Cancellazione anagrafica', '5 - Cittadinanza', '7 - Esistenza in vita', '8 - Residenza', '10 - Residenza AIRE', '11 - Stato civile', '12 - Stato di famiglia', '13 - Stato di famiglia e di stato civile', '14 - Residenza in convivenza', '15 - Stato di famiglia AIRE', '16 - Stato di famiglia con rapporti di parentela', '17 - di Stato Libero', '18 - Anagrafico di Unione Civile', '19 - di Contratto di Convivenza'] 
    while x < 10      
      nome_random = rand(nomi_certificati.length)
      cf_generato = random_cf
      certificato = {
        tenant: "97d6a602-2492-4f4c-9585-d2991eb3bf4c",
        codice_fiscale: cf_generato,
        codice_certificato: nomi_certificati[nome_random],
        bollo: rand_bool,
        diritti_segreteria: rand_bool,
        uso: "",
        richiedente_cf: ( rand_bool ? cf_generato : random_cf ),
        # richiesta: "",
        stato: "nuovo",
        # data_inserimento: "",
        data_prenotazione: rand_time(30.days.ago),
        # email: "",
        id_utente: rand(1000),
        # documento: "",
        nome_certificato: nomi_certificati[nome_random],
      }
      Certificati.create(certificato)
      array_json << certificato
   
      x = x + 1
    end    
    response = array_json.to_json  
    render :json => response
  end

  private

  def createPath(tree)
    path = File.dirname("data")
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
    end

    path = File.join(path, "data")

    tree.each do |dir|
      path = File.join(path, dir)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end
    end
    return path
  end

  # funzione per test
  def rand_in_range(from, to)
    rand * (to - from) + from
  end

  # funzione per test
  def rand_bool()
    return rand(2)>0
  end

  # funzione per test
  def rand_time(from, to=Time.now)
    Time.at(rand_in_range(from.to_f, to.to_f))
  end

  # funzione per test
  def random_cf
    o = [('A'..'Z')].map(&:to_a).flatten
    string = (0...6).map { o[rand(o.length)] }.join + rand(99).to_s + o[rand(o.length)] + rand(71).to_s + o[rand(o.length)] + rand(999).to_s + o[rand(o.length)]
    return string
  end

  def autentica_ente
    puts "autentica_ente"
    if !request.headers['HTTP_AUTHORIZATION'].blank? #authorization con token jwt
      token_jwt = request.headers['HTTP_AUTHORIZATION'].gsub('Bearer ','')
      jwt_decoded = []
      begin
        jwt_decoded = JsonWebToken.decode(token_jwt)      
      rescue => exc
        return { 'esito' => 'ko', 'msg_errore' => exc.message }
      rescue JWT::DecodeError => exc_jwt
        return { 'esito' => 'ko', 'msg_errore' => exc_jwt.message }
      end

      if jwt_decoded.nil?
        puts "decoded nil"
        return { 'esito' => 'ko', 'msg_errore' => "Errore decodifica token!" }
      else
        #verifica della scadenza
        if Time.current.utc.to_i > jwt_decoded['exp'] 
          return { 'esito' => 'ko', 'msg_errore' => "Autenticazione scaduta!" }
        end
        puts jwt_decoded
        return { 'esito' => 'ok' }
        #verifica del client id..da implementare invio del client_id su auth_hub
        # jti = jwt_decoded['jti']
        # client_id = OpenSSL::Digest::SHA256.new(get_dbname+jti)
        # raise "Verifica del client_id fallito" if client_id != jwt_decoded['client_id']
      end

    else
      return { 'esito' => 'ko', 'msg_errore' => "Autenticazione mancante!" }
    end
  end

end