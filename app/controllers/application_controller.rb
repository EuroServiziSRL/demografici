require 'httparty'
require 'uri'
require "base64"
require 'openssl'
require 'zlib'
require 'autocert_date_time'
# begin
#   require 'serenity' if ['odt', 'pdf'].include?(Spider.config.get('demografici.formato_autocertificazioni'))
#   # require 'pdfkit'
# rescue LoadError => exc
# end

begin
  require 'serenity'
rescue LoadError => exc
  debug_message("error loading serenity", 3)
  debug_message(exc, 3)
end

## auth su api
# https://login.microsoftonline.com/97d6a602-2492-4f4c-9585-d2991eb3bf4c/oauth2/token
# L’ambiente di Test su UAT è UAT281: ( DEDA UAT281 - DEMO DEMOGRAFIA 2 – id 348 )
# Application ID:
# aebe50cd-bbc0-4bf5-94ba-4e70590bcf1a
# Secret:
# w9=jyc0bA.sBVLX@aHD:87lPZlS4r=7x

class ApplicationController < ActionController::Base
  include ApplicationHelper
  # include Serenity::Generator if ['odt', 'pdf'].include?(Spider.config.get('demografici.formato_autocertificazioni'))
  include Serenity::Generator
  # TODO aggiungere anche resource in config?
  # @@api_resource = "https://api.civilianextuat.it"
  @@api_resource = "https://api.civilianextdev.it"
  @@api_url = "#{@@api_resource}/Demografici"
  PERMESSI = ["ricercare_anagrafiche", "ricercare_anagrafiche_no_sensibili", "elencare_anagrafiche", "vedere_solo_famiglia", "professionisti", "elencare_anagrafiche_certificazione", "cittadino"].freeze
  @@log_level = 0
  @@log_to_output = true
  @@log_to_file = false
  before_action :get_dominio_sessione_utente, :get_layout_portale, :carica_variabili_layout, :test_variables
  
  #ROOT della main_app
  def index
    # debug_message("PERMESSI:", 3)
    # debug_message(PERMESSI, 3)
    # session[:cf] = 'ZMMRHG87L05Z600V'
    # session[:client_id] = 768

    # 
    #carico cf in variabile per usarla sulla view
    debug_message("index - session[:cf]: "+session[:cf], 3)
    debug_message("index - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s, 3)
    @cf_utente_loggato = session[:cf]
    if PERMESSI[session[:permessi]] == "cittadino"
      @page_app = "dettagli_persona"
    else
      @page_app = "ricerca_anagrafiche"
    end
     
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"

  end

  def dettagli_persona
    # debug_message("dettagli_persona - session[:cf]: "+session[:cf], 3)
    # debug_message("dettagli_persona - params[\"codice_fiscale\"]: "+params["codice_fiscale"], 3)
    # debug_message("dettagli_persona - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s, 3)
    @page_app = "dettagli_persona"

    if params["codice_fiscale"].nil?
      params["codice_fiscale"] = session[:cf]
      session[:cf_visualizzato] = nil
    elsif params["codice_fiscale"] == session[:cf]
      session[:cf_visualizzato] = nil
      debug_message("session[:cf_visualizzato] set to null", 3)
    else
      session[:cf_visualizzato] = params["codice_fiscale"]
      debug_message("session[:cf_visualizzato] now is: "+session[:cf_visualizzato].to_s, 3)
    end
    debug_message("session is:", 3)
    debug_message(session.class.inspect, 3)
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
  end

  def richiedi_certificato
    # ricevo dal portale del cittadino una richiesta di certificato
    # il portale deve inviarmi il tenant
    # inserisco in certificati la richiesta ricevuta con stato appropriato 
    # richiesto se !bollo&&!segreteria, da pagare se bollo||segreteria
    # restituisco risultato inserimento e id richiesta
    # se da pagare, poi il portale farà un redirect su pagamenti
    cf_certificato = session[:cf]
    if !session[:cf_visualizzato].nil? &&! session[:cf_visualizzato].blank? 
      cf_certificato = session[:cf_visualizzato]
    end

    @page_app = "richiedi_certificato"

    nome_certificato = ""
    tipo_certificato = TipoCertificato.find_by_id(params[:tipoCertificato])  
    if !tipo_certificato.blank? || !tipo_certificato.nil?
      nome_certificato = tipo_certificato.descrizione
    end

    cartaLibera = !params[:certificatoBollo].nil? && !params[:certificatoBollo].blank? &&  params[:certificatoBollo] != "true"
    esenzioneBollo = !params[:esenzioneBollo].nil? && !params[:esenzioneBollo].blank? &&  params[:esenzioneBollo] != "0"
    # TODO -WAIT- implementare recupero diritti segreteria da api quando sarà disponibile
    if cartaLibera || esenzioneBollo
      importo_bollo = 0 # importo bollo è 0 su carta libera o se è specificata esenzione
    else
      importo_bollo = 16 # altrimenti è 16 (importo fisso)
    end
    
    # TODO -WAIT- recuperare diritti segreteria da api quando sarà disponibile
    # i diritti di segreteria sono solitamente 0.26 per carta libera e 0.52 per bollo, se vengono applicati
    importo_segreteria = ( rand(2)>0 ? 0 : 0.52 )
    if cartaLibera
      importo_segreteria = ( rand(2)>0 ? 0 : 0.26 )
    end

    certificato = {
      tenant: session[:api_next_tenant], 
      codice_fiscale: cf_certificato,
      codici_certificato: [params[:tipoCertificato].to_i],
      bollo: importo_bollo,
      bollo_esenzione: params[:esenzioneBollo],
      nome_certificato: nome_certificato,
      # TODO -WAIT- aggiungere importo quando l'api lo fornirà
      # diritti_importo: importo_segreteria,
      diritti_importo: 0, # per ora sempre a 0 perchè non cè l'api
      uso: params[:motivoEsenzione],
      richiedente_cf: session[:cf],
      richiedente_nome: session[:nome],
      richiedente_cognome: session[:cognome],
      richiedente_doc_riconoscimento: "#{session[:tipo_documento]} #{session[:numero_documento]}",
      richiedente_doc_data: session[:data_documento],
      richiedente_data_nascita: session[:data_nascita],
      # richiesta: "", # non usato
      stato: "nuovo",
      # data_inserimento: "", # data inserimento del certificato che verrà inserito dall'ente
      data_prenotazione: Time.now,
      email: session[:email],
      id_utente: session[:user_id],
      # documento: "", # il certificato che verrà inserito dall'ente
    }

    Certificati.create(certificato)    

    # session[:cf_visualizzato] = params["codice_fiscale"]
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
  end

  def ricerca_anagrafiche
    @page_app = "ricerca_anagrafiche"
    @nome = session[:nome]
    
    if PERMESSI[session[:permessi]] == "cittadino"
      debug_message("redirecting to /", 3)
      redirect_to "/"
      return
    else 
      # session[:cf_visualizzato] = params["codice_fiscale"]
      render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
    end
  end
  
  def authenticate  
    debug_message("authenticate - session[:cf]: "+session[:cf], 3)
    debug_message("authenticate - params[\"codice_fiscale\"]: "+params["codice_fiscale"].to_s, 3)
    debug_message("authenticate - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s, 3)
    requestParams = {
      "resource": "#{@@api_resource.sub("https","http")}", 
      "tenant": "#{session[:api_next_tenant]}",
      "client_id": "#{session[:api_next_client_id]}",
      "client_secret": "#{session[:api_next_secret]}",
      "grant_type": 'client_credentials'
    }

    oauthURL = "https://login.microsoftonline.com/#{requestParams[:tenant]}/oauth2/token";
    result = HTTParty.post(oauthURL, 
      :body => requestParams.to_query,
      :headers => { 'Content-Type' => 'application/x-www-form-urlencoded','Accept' => 'application/json'  } ,
      :debug_output => $stdout
    )

    if !result["access_token"].nil? && result["access_token"].length > 0
      debug_message("setting token into session", 3)
      session[:token] = result["access_token"]
      result["csrf"] = form_authenticity_token
    elsif !result["message"].nil? && result["message"].length > 0
      if result["message"] == "Authorization has been denied for this request."
        result = { 
          "errore": true, 
          "messaggio_errore": "Si è verificato un problema di connessione al servizio.", 
        }
      else
        result = { 
          "errore": true, 
          "messaggio_errore": "Errore generico durante la connessione al servizio.", 
        }
      end
    end
    
    # result["url"] = oauthURL
    # result["params"] = params

    render :json => result
  end  

  def ricerca_anagrafiche_individui
    debug_message("ricerca_anagrafiche_individui", 3)
    debug_message("PERMESSI[session[:permessi]]: "+PERMESSI[session[:permessi]], 3)

    if !params[:cognomeNome].nil? || !params[:cognomeNome].blank?
      params[:cognomeNome] = "%#{params[:cognomeNome]}%"
    end
    params[:MostraIndirizzo] = true

    tipologia_richiesta = "ricerca anagrafiche"

    if !verifica_permessi("ricerca_anagrafiche")
      tipologia_richiesta = "#{tipologia_richiesta} (non autorizzato)"

      result = { 
        "errore": true, 
        "messaggio_errore": "Non sei autorizzato a visualizzare questi dati.", 
      }
    else      
      result = HTTParty.post(
        "#{@@api_url}/Anagrafe/RicercaIndividui?v=1.0", 
        :body => params.to_json,
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "Bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )   
      result = JSON.parse(result.response.body)
      if PERMESSI[session[:permessi]]!="elencare_anagrafiche"
        base_url = '/dettagli_persona?codice_fiscale='
        result.each_with_index do |anagrafica,index|
          cf = anagrafica["codiceFiscale"]
          anagrafica["codiceFiscale"] = "<a href='#{base_url}#{cf}'>#{cf}</a>".html_safe
          result[index] = anagrafica
        end 
      end
      result = { "data": result }
    end

    traccia_operazione(tipologia_richiesta)

    render :json => result
  end

  def inserisci_pagamento
    searchParams = {}
    searchParams[:tenant] = session[:api_next_tenant]
    searchParams[:id_utente] = session[:user_id]
    searchParams[:id] = params[:id]
    richiesta_certificato = Certificati.where("id = :id AND tenant = :tenant AND id_utente = :id_utente", searchParams).first
    importo = 0
    if !richiesta_certificato.bollo.nil?
      importo = importo+richiesta_certificato.bollo
    end
    if !richiesta_certificato.diritti_importo.nil?
      importo = importo+richiesta_certificato.diritti_importo
    end
    parametri = {
      importo: "#{importo}",
      descrizione: "Certificato #{richiesta_certificato.nome_certificato} per #{richiesta_certificato.codice_fiscale} - n.#{richiesta_certificato.id}",
      codice_applicazione: "demografici", # TODO va bene questo codice applicazione?
      url_back: request.protocol + request.host_with_port,
      idext: richiesta_certificato.id,
      tipo_elemento: "certificazione_td",
      nome_versante: session[:nome],
      cognome_versante: session[:cognome],
      codice_fiscale_versante: session[:cf],
      nome_pagatore: session[:nome],
      cognome_pagatore: session[:cognome],
      codice_fiscale_pagatore: session[:cf]
    }
    
    queryString = [:importo, :descrizione, :codice_applicazione, :url_back, :idext, :tipo_elemento, :nome_versante, :cognome_versante, :codice_fiscale_versante, :nome_pagatore, :cognome_pagatore, :codice_fiscale_pagatore].map{ |chiave|
        val = parametri[chiave] 
        "#{chiave}=#{val}"
    }.join('&')
    
    # debug_message("query string for sha1 is [#{queryString.strip}]", 3)
    # queryString = "importo=#{value["importoResiduo"].gsub(',', '.')}&descrizione=#{value["codiceAvvisoDescrizione"]} - n.#{value["numeroAvviso"]}&codice_applicazione=tributi&url_back=#{request.original_url}&idext=#{value["idAvviso"]}&tipo_elemento=pagamento_tari&nome_versante=#{session[:nome]}&cognome_versante=#{session[:cognome]}&codice_fiscale_versante=#{session[:cf]}&nome_pagatore=#{session[:nome]}&cognome_pagatore=#{session[:cognome]}&codice_fiscale_pagatore=#{session[:cf]}"
    fullquerystring = URI.unescape(queryString)
    # qs = fullquerystring.sub(/&hqs=\w*/,"").strip+"3ur0s3rv1z1"
    qs = queryString+"3ur0s3rv1z1"
    hqs = OpenSSL::Digest::SHA1.new(qs)
    url = "#{session[:dominio]}/servizi/pagamenti/aggiungi_pagamento_pagopa.json?#{queryString}&hqs=#{hqs}&id_utente=#{session[:user_id]}&sid=#{session[:user_sid]}"
    result = HTTParty.post(
      url, 
      :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json' } ,
      :debug_output => $stdout
    )   
    result = JSON.parse(result.response.body)
    render :json => result
  end

  def ricerca_individui
    @@log_level = 3
    debug_message("ricerca_individui - logged user cf: "+session[:cf], 3)
    debug_message("ricerca_individui - cf_visualizzato: "+session[:cf_visualizzato].to_s, 3)
    debug_message("ricerca_individui - \"cf_visualizzato\": "+session["cf_visualizzato"].to_s, 3)
    debug_message("ricerca_individui - permessi: "+session[:permessi].to_s+" (#{PERMESSI[session[:permessi]]})", 3)

    tipologia_richiesta = ""
        
    cf_ricerca = session[:cf_visualizzato]
    if session[:cf_visualizzato].nil? || session[:cf_visualizzato].blank? 
      cf_ricerca = session[:cf]
    elsif session[:cf_visualizzato] == session[:cf]
      cf_ricerca = session[:cf]
    end

    if cf_ricerca == session[:cf] 
      tipologia_richiesta = "visualizzazione propria anagrafica"
    elsif cf_ricerca.in?(session[:famiglia])
      tipologia_richiesta = "visualizzazione anagrafica familiare #{cf_ricerca}"
    else
      tipologia_richiesta = "visualizzazione altra anagrafica #{cf_ricerca}"
    end

    if !verifica_permessi("visualizza_anagrafica")
      tipologia_richiesta = "#{tipologia_richiesta} (non autorizzato)"

      result = { 
        "errore": true, 
        "messaggio_errore": "Non sei autorizzato a visualizzare questi dati.", 
      }
    else
      searchParams = { "CodiceFiscale": cf_ricerca }

      nascondi_sensibili = !is_self && ["ricercare_anagrafiche_no_sensibili","vedere_solo_famiglia","professionista_limitato"].include?(PERMESSI[session[:permessi]])
      solo_certificati = PERMESSI[session[:permessi]] == "elencare_anagrafiche_certificazione"
      solo_famiglia = PERMESSI[session[:permessi]] == "vedere_solo_famiglia"
      cittadino = PERMESSI[session[:permessi]] == "cittadino"
      professionista = ["professionisti","elencare_anagrafiche_certificazione"].include?(PERMESSI[session[:permessi]])
      globale = ["ricercare_anagrafiche","ricercare_anagrafiche_no_sensibili","elencare_anagrafiche","vedere_solo_famiglia"].include?(PERMESSI[session[:permessi]])

      debug_message("session[:permessi]: #{session[:permessi]} - PERMESSI[session[:permessi]]: #{PERMESSI[session[:permessi]]}", 3)
      debug_message("is_self? "+is_self.to_s, 3)
      debug_message('PERMESSI[session[:permessi]] == "ricercare_anagrafiche_no_sensibili"? ' + (PERMESSI[session[:permessi]] == "ricercare_anagrafiche_no_sensibili").to_s, 3)
      debug_message('nascondi_sensibili? '+nascondi_sensibili.to_s, 3)
      debug_message("solo_certificati? "+solo_certificati.to_s, 3)
      debug_message("solo_famiglia? "+solo_famiglia.to_s, 3)
      debug_message("cittadino? "+cittadino.to_s, 3)
      debug_message("professionista? "+professionista.to_s, 3)
      debug_message("globale? "+globale.to_s, 3)

      searchParams[:MostraIndirizzo] = true
      searchParams[:MostraConiuge] = true
      searchParams[:MostraDatiDecesso] = true
      searchParams[:MostraDatiTitoloSoggiorno] = true
      searchParams[:MostraDatiStatoCivile] = true
      searchParams[:MostraDatiCartaIdentita] = !professionista
      searchParams[:MostraDatiPatenti] = !professionista
      searchParams[:MostraDatiVeicoli] = !professionista
      searchParams[:MostraDatiMaternita] = !nascondi_sensibili
      searchParams[:MostraDatiPaternita] = !nascondi_sensibili
      searchParams[:MostraDatiProfessione] = !nascondi_sensibili
      searchParams[:MostraDatiTitoloStudio] = !nascondi_sensibili
      

      debug_message("searchParams: ", 3)
      debug_message(searchParams, 3)

      result = HTTParty.post(
        "#{@@api_url}/Anagrafe/RicercaIndividui?v=1.0", 
        :body => searchParams.to_json,
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "Bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )    
      # result = result.response.body
      if result.response.body.length > 0
        result = JSON.parse(result.response.body)
        result = result[0]
      else
        result = ""
      end
      if !result.nil? && result.length > 0
        famiglia = []
        session[:famiglia] = []

        if solo_famiglia || solo_certificati
          new_result = { }
          
          new_result["nome"] = result["nome"]
          new_result["cognome"] = result["cognome"]
          new_result["codiceFiscale"] = result["codiceFiscale"]
          new_result["codiceFamiglia"] = result["codiceFamiglia"]

          result = new_result

          debug_message("result set to", 3)
          debug_message(result, 3)
        elsif nascondi_sensibili
          result.except!("dataNascita")
          result.except!("codiceIstatComuneNascitaItaliano")
          result["datiDecesso"]["data"] = result["datiDecesso"]["data"].gsub(/T.+/,"") unless result["datiDecesso"].nil?
          result["datiStatoCivile"]["divorzio"].except!("tipo") unless result["datiStatoCivile"].nil? || result["datiStatoCivile"]["divorzio"].nil?
          result["datiStatoCivile"]["divorzio"].except!("dataSentenza") unless result["datiStatoCivile"].nil? || result["datiStatoCivile"]["divorzio"].nil?

          # divorzio, elettorale e documenti nascosti se non è parziale o professionista
          # nominativo familiare visibile solo se globale o professionista

          debug_message("divorzio set to", 3)
          debug_message(result["datiStatoCivile"]["divorzio"], 3)
        else
          if professionista
            result["datiStatoCivile"].except!("divorzio") unless result["datiStatoCivile"].nil?
            result["datiStatoCivile"].except!("divorzio") unless result["datiStatoCivile"].nil?
          end

          comune = get_comune(result["codiceIstatComuneNascitaItaliano"], result["dataNascita"])
          debug_message("comune: #{comune}", 3)
          if !comune.blank? && !comune.nil? && comune
            result["comuneNascitaDescrizione"] = comune
          elsif !result["descrizioneComuneNascitaEstero"].blank?
            stato = get_stato_estero(result["codiceIstatNazioneNascitaEstero"], result["dataNascita"])
            result["comuneNascitaDescrizione"] = result["descrizioneComuneNascitaEstero"]+" (#{stato})"
          else
            result["comuneNascitaDescrizione"] = "";
          end
        end


        result["datiRichiedente"] = {
          "nome": session[:nome], 
          "cognome": session[:cognome], 
          "cf": session[:cf], 
          "data_nascita": session[:data_nascita], 
          "tipo_documento": session[:tipo_documento], 
          "numero_documento": session[:numero_documento], 
          "data_documento": session[:data_documento], 
        }

        debug_message("datiRichiedente set to", 3)
        debug_message(result["datiRichiedente"], 3)
        
        if !result["codiceFamiglia"].blank? && result["codiceFamiglia"]!="null" && ( cittadino || globale || professionista || solo_famiglia  )
          debug_message("fetching famiglia", 3)
          searchParams = { 
            "codiceAggregazione": result["codiceFamiglia"], 
          }
          resultFamiglia = HTTParty.post(
            "#{@@api_url}/Anagrafe/RicercaComponentiFamiglia?v=1.0", 
            :body => searchParams.to_json,
            :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "Bearer #{session[:token]}" } ,
            :debug_output => $stdout
          )    
          resultFamiglia = JSON.parse(resultFamiglia.response.body)
          famigliaArray = []
          resultFamiglia.each do |componente|
            debug_message("looping through resultFamiglia, componente:", 3)
            debug_message(componente, 3)
            relazione = RelazioniParentela.where(id_relazione: componente["codiceRelazioneParentelaANPR"]).first
            componente["relazioneParentela"] = relazione.descrizione
            famigliaArray << componente["codiceFiscale"]
            famiglia << componente
          end
          session[:famiglia] = famigliaArray.to_json
          result["famiglia"] = famiglia
          result["csrf"] = form_authenticity_token
        end

        if ( cittadino || professionista || solo_certificati ) && !solo_famiglia

          result["certificati"] = []
          result["richiesteCertificati"] = []

          searchParams = {}
          searchParams[:tenant] = session[:api_next_tenant]
          searchParams[:id_utente] = session[:user_id]
          # searchParams[:codice_fiscale] = cf_ricerca
          richieste_certificati = Certificati.where("tenant = :tenant AND id_utente = :id_utente", searchParams).order("created_at DESC")
          richieste_certificati.each do |richiesta_certificato|
            importo = 0
            if !richiesta_certificato.bollo.nil?
              importo = importo+richiesta_certificato.bollo
            end
            if !richiesta_certificato.diritti_importo.nil?
              importo = importo+richiesta_certificato.diritti_importo
            end

            if richiesta_certificato.stato == "pagato" || richiesta_certificato.stato == "da_pagare"
              url = richiesta_certificato.documento
              scaduto = false
              debug_message("data inserimento", 3)
              debug_message(richiesta_certificato.data_inserimento, 3)
              debug_message("180.days.ago", 3)
              debug_message(180.days.ago, 3)

              if 180.days.ago >= richiesta_certificato.data_inserimento
                scaduto = true
              end
              
              if !scaduto && richiesta_certificato.stato == "da_pagare"
                statoPagamenti = stato_pagamento("#{session[:dominio].gsub("https","http")}/servizi/pagamenti/ws/stato_pagamenti",richiesta_certificato.id)
                # TODO **IMPORTANT** sostituire stato_pagamento con verifica_pagamento
                # TODO **IMPORTANT** aggiungere marca da bollo
                # verificaPagamento = verifica_pagamento("#{session[:dominio].gsub("https","http")}/servizi/pagamenti/ws/10/verifica_pagamento",richiesta_certificato.id)
                # debug_message("verifica pagamento response", 3)
                # debug_message(verificaPagamento, 3)
                if(!statoPagamenti.nil? && statoPagamenti["esito"]=="ok" && (statoPagamenti["esito"][0]["stato"]=="Pagato"))
                  # pagato, lascio scaricare il documento
                  url = "/scarica_certificato?file=#{richiesta_certificato.documento.gsub('./','')}"
                else                  
                  url = "#{session[:dominio]}/servizi/pagamenti/"
                  debug_message(statoPagamenti, 3)
                  debug_message(statoPagamenti["esito"], 3)
                  if(statoPagamenti.nil? || statoPagamenti["esito"]!="ok")
                    debug_message("statoPagamenti NOT OK", 3)
                    if false
                      url = "/inserisci_pagamento?id=#{richiesta_certificato.id}"
                    else
                      importo = 0
                      if !richiesta_certificato.bollo.nil?
                        importo = importo+richiesta_certificato.bollo
                      end
                      if !richiesta_certificato.diritti_importo.nil?
                        importo = importo+richiesta_certificato.diritti_importo
                      end
                      parametri = {
                        importo: "#{importo}",
                        descrizione: "Certificato #{richiesta_certificato.nome_certificato} per #{richiesta_certificato.codice_fiscale} - n.#{richiesta_certificato.id}",
                        codice_applicazione: "demografici", # TODO va bene questo codice applicazione?
                        url_back: request.protocol + request.host_with_port,
                        idext: richiesta_certificato.id,
                        tipo_elemento: "certificazione_td",
                        nome_versante: session[:nome],
                        cognome_versante: session[:cognome],
                        codice_fiscale_versante: session[:cf],
                        nome_pagatore: session[:nome],
                        cognome_pagatore: session[:cognome],
                        codice_fiscale_pagatore: session[:cf]
                      }
                      
                      queryString = [:importo, :descrizione, :codice_applicazione, :url_back, :idext, :tipo_elemento, :nome_versante, :cognome_versante, :codice_fiscale_versante, :nome_pagatore, :cognome_pagatore, :codice_fiscale_pagatore].map{ |chiave|
                          val = parametri[chiave] 
                          "#{chiave}=#{val}"
                      }.join('&')
                      
                      # debug_message("query string for sha1 is [#{queryString.strip}]", 3)
                      # queryString = "importo=#{value["importoResiduo"].gsub(',', '.')}&descrizione=#{value["codiceAvvisoDescrizione"]} - n.#{value["numeroAvviso"]}&codice_applicazione=tributi&url_back=#{request.original_url}&idext=#{value["idAvviso"]}&tipo_elemento=pagamento_tari&nome_versante=#{session[:nome]}&cognome_versante=#{session[:cognome]}&codice_fiscale_versante=#{session[:cf]}&nome_pagatore=#{session[:nome]}&cognome_pagatore=#{session[:cognome]}&codice_fiscale_pagatore=#{session[:cf]}"
                      fullquerystring = URI.unescape(queryString)
                      # qs = fullquerystring.sub(/&hqs=\w*/,"").strip+"3ur0s3rv1z1"
                      qs = queryString+"3ur0s3rv1z1"
                      hqs = OpenSSL::Digest::SHA1.new(qs)
                      url = "#{session[:dominio]}/servizi/pagamenti/aggiungi_pagamento_pagopa.json?#{queryString}&hqs=#{hqs}&id_utente=#{session[:user_id]}&sid=#{session[:user_sid]}"
                    end
                  else
                    debug_message("statoPagamenti OK", 3)
                  end
                end
              elsif !scaduto && richiesta_certificato.stato == "pagato"
                url = "/scarica_certificato?file=#{richiesta_certificato.documento.gsub('./','')}"
              else
                url = ""
              end
              # scaricabile solo una volta, vedere su velletri o giugliano
              # TODO non mostrare certificati scaduti
              result["certificati"] << { 
                "id": richiesta_certificato.id, 
                "nome_certificato": richiesta_certificato.nome_certificato, 
                "codice_fiscale": richiesta_certificato.codice_fiscale, 
                "stato": scaduto ? "scaduto" : richiesta_certificato.stato, 
                "documento": url,
                "data_prenotazione": richiesta_certificato.data_prenotazione,
                "data_inserimento": richiesta_certificato.data_inserimento,
                "esenzione": richiesta_certificato.bollo_esenzione, 
                "importo": importo
              }
            else
              result["certificati"] << { 
                "id": richiesta_certificato.id, 
                "nome_certificato": richiesta_certificato.nome_certificato, 
                "codice_fiscale": richiesta_certificato.codice_fiscale, 
                "stato": richiesta_certificato.stato, 
                "documento": "",
                "data_prenotazione": richiesta_certificato.data_prenotazione,
                "data_inserimento": "",
                "esenzione": richiesta_certificato.bollo_esenzione, 
                "importo": importo
              }
            end
          end

        end

        if PERMESSI[session[:permessi]]=="cittadino"
          # recupero anche le autocertificazioni
          files = Dir.glob("#{Rails.root}/autocertificazioni/odt/*")
          result["autocertificazioni"] = []
          files.each do |percorso|
            filename = File.basename(percorso)
            result["autocertificazioni"] << { 
              "preText": filename.sub(".odt"," ").sub(/\d{1,2} /,""), 
              "text": " - scarica documento".html_safe, 
              "url": request.protocol+request.host_with_port+"/scarica_autocertificazione/?nome=#{filename}", 
            }
          end
        end

        result["isSelf"] = is_self
      elsif !result.nil? && result.length == 0
        result = { 
          "errore": true, 
          "messaggio_errore": "Impossibile trovare l'anagrafica richiesta.", 
        }
      elsif result.nil? && fullResult.nil?
        result = { 
          "errore": true, 
          "messaggio_errore": "Impossibile recuperare i dati.", 
        }
      elsif !fullResult["message"].nil? && fullResult["message"].length > 0 && fullResult["message"] == "Authorization has been denied for this request."
        result = { 
          "errore": true, 
          "messaggio_errore": "Si è verificato un problema di connessione al servizio. Si prega di riprovare più tardi.", 
        }
      else
        result = { 
          "errore": true, 
          "messaggio_errore": "Si è verificato un errore generico durante l'interrogazione dei dati.", 
        }
      end

    end

    # debug_message("ricerca individui done, tracking request", 3)
    traccia_operazione(tipologia_richiesta)
    # debug_message("request tracked, result is:", 3)
    # debug_message(result, 3)

    render :json => result
  end

  def scarica_certificato
    tipologia_richiesta = "download certificato #{params["file"]}"
    if verifica_permessi("scarica_certificato")
      traccia_operazione(tipologia_richiesta)
      send_file "#{Rails.root}/#{params["file"]}", type: "application/pdf", x_sendfile: true
    else
      tipologia_richiesta = "#{tipologia_richiesta} (non autorizzato)"
      traccia_operazione(tipologia_richiesta)
      render html: '<DOCTYPE html><html><head><title>Non autorizzato</title></head><body>Non sei autorizzato a visualizzare questo file.</body></html>'.html_safe
    end
  end

  def scarica_autocertificazione
    content_type = {:rtf => "text/rtf", :pdf => "application/pdf", :odt => "application/vnd.oasis.opendocument.text"}
    cf = params['codice_fiscale']
    nome = CGI.unescape(params['nome'])
    # new_pdf_method = true
    # begin
    #     require 'docsplit' if Spider.config.get('demografici.formato_autocertificazioni') == 'pdf'
    # rescue LoadError => exc
    #     new_pdf_method = false
    # end
    new_pdf_method = false
    # end_format = Spider.config.get('demografici.formato_autocertificazioni').to_sym
    end_format = :odt
 
    if new_pdf_method
        case end_format
            when :odt, :pdf
                format = :odt
            when :rtf
                format = end_format
        end 
    else 
        format = end_format
    end

    cf_ricerca = session[:cf_visualizzato]
    if session[:cf_visualizzato].nil? || session[:cf_visualizzato].blank? 
      cf_ricerca = session[:cf]
    elsif session[:cf_visualizzato] == session[:cf]
      cf_ricerca = session[:cf]
    end

    searchParams = { "CodiceFiscale": cf_ricerca }
    searchParams[:MostraIndirizzo] = true
    searchParams[:MostraConiuge] = true
    searchParams[:MostraDatiStatoCivile] = true

    result = HTTParty.post(
      "#{@@api_url}/Anagrafe/RicercaIndividui?v=1.0", 
      :body => searchParams.to_json,
      :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "Bearer #{session[:token]}" } ,
      :debug_output => $stdout
    )    
    result = JSON.parse(result.response.body)
    result = result[0]
    if !result.nil? && result.length > 0

      comune = get_comune(result["codiceIstatComuneNascitaItaliano"], result["dataNascita"])
      if !comune.blank? && !comune.nil? && comune
        result["comuneNascitaDescrizione"] = comune
      elsif !result["descrizioneComuneNascitaEstero"].blank?
        stato = get_stato_estero(result["codiceIstatNazioneNascitaEstero"], result["dataNascita"])
        result["comuneNascitaDescrizione"] = result["descrizioneComuneNascitaEstero"]+" (#{stato})"
      else
        result["comuneNascitaDescrizione"] = "";
      end

      now = Time.now.strftime("%d/%m/%Y")
      comune = get_comune(result["codiceIstatComuneResidenzaItaliano"], now)
      if !comune.blank? && !comune.nil? && comune
        result["comuneResidenzaDescrizione"] = comune
      elsif !result["descrizioneComuneResidenzaEstero"].blank?
        stato = get_stato_estero(result["codiceIstatResidenzaResidenzaEstero"], now)
        result["comuneResidenzaDescrizione"] = result["descrizioneComuneNascitaEstero"]+" (#{stato})"
      else
        result["comuneResidenzaDescrizione"] = "";
      end

      coniuge = { "cognome" => "", "nome" => "", "oa" => "", "comune_nascita" => "", "data_nascita" => "" }
      if !result["datiStatoCivile"]["matrimonio"].blank? && !result["datiStatoCivile"]["matrimonio"].nil?
        resultConiuge = result["datiStatoCivile"]["matrimonio"]["coniuge"]
        coniuge = { 
          "cognome" => resultConiuge["cognome"], 
          "nome" => resultConiuge["cognome"], 
          "oa" => "", 
          "comune_nascita" => "", 
          "data_nascita" => "" 
        }
      end


      @persona = {
        "nome" => result["nome"],
        "cognome" => result["cognome"],
        "codice_fiscale" => result["codiceFiscale"],
        "comune_nascita" => result["comuneNascitaDescrizione"],
        "data_nascita" => result["dataNascita"],
        # "indirizzo_residenza" => indirizzo,
        "cittadinanza" => { "descrizione" => result["descrizioneCittadinanza"] },
        "coniuge" => { "cognome" => "", "nome" => "", "oa" => "", "comune_nascita" => "", "data_nascita" => "" },
        "stato_civile" => { "codice_istat" => result["statoCivile"] },
      }
      @oa = result["sesso"] == "M" ? "o": "a"
      @illa = result["sesso"] == "M" ? "il": "la" 
      @data = now
      searchParams = { 
        "codiceAggregazione": result["codiceFamiglia"], 
      }
      resultFamiglia = HTTParty.post(
        "#{@@api_url}/Anagrafe/RicercaComponentiFamiglia?v=1.0", 
        :body => searchParams.to_json,
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "Bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )    
      resultFamiglia = JSON.parse(resultFamiglia.response.body)
      @famiglia = []
      resultFamiglia.each do |componente|
        relazione = RelazioniParentela.where(id_relazione: componente["codiceRelazioneParentelaANPR"]).first
        debug_message("TYPEOF ", 3)
        debug_message(relazione.inspect, 3)
        componente["relazioneParentela"] = relazione.descrizione
        @famiglia << {
          "nome" => componente["nome"],
          "cognome" => componente["cognome"],
          "relazione_parentela" => componente["relazioneParentela"],
          "data_nascita" => componente["dataNascita"],
          "comune_nascita" => "", # non c'è!
        }
      end

      json = @persona.to_json
      @persona = JSON.parse(json, object_class: OpenStruct)

      @persona.data_nascita = AutocertDateTime.parse(@persona.data_nascita).to_date
      @persona.indirizzo_residenza = Indirizzo.new({ "indirizzo" => result["indirizzo"], "comune" => result["comuneResidenzaDescrizione"] })

      # debug_message("persona is", 3)
      # debug_message(@persona, 3)
      # debug_message("data_nascita is", 3)
      # debug_message(@persona.data_nascita.class.name, 3)
      # debug_message("indirizzo_residenza is", 3)
      # debug_message(@persona.indirizzo_residenza, 3)
      # debug_message(@persona.indirizzo_residenza.comune, 3)
      # debug_message(@persona.indirizzo_residenza.indirizzo, 3)
      # debug_message(@persona.indirizzo_residenza.class.name, 3)
      # debug_message("data_nascita.lformat", 3)
      # debug_message(@persona.data_nascita.lformat, 3)

      json = @famiglia.to_json
      @famiglia = JSON.parse(json, object_class: OpenStruct)
      @famiglia.each_with_index do |membro,index|
        membro.data_nascita = AutocertDateTime.parse(membro.data_nascita).to_date
        @famiglia[index] = membro
      end 
      debug_message(@famiglia, 3)
      # @famiglia.each do |indice,membro|
      #   membro.data_nascita = AutocertDateTime.parse(membro.data_nascita).to_date
      #   @famiglia[indice] = membro
      # end
    end

    raise NotFound.new("Autocertificazione #{nome} formato '#{format}'") unless [:rtf, :pdf, :odt].include?(format)

    
    # salva_traccia('autocertificazioni', @request.params.convert_object.to_json)

    if format == :rtf
      # ???
      # if RUBY_VERSION =~ /1.8/
      #     scene.data = iconv.iconv(scene.data)
      # else
      #     scene.data = scene.data.encode('cp1252','utf-8').force_encoding('utf-8')
      #     scene.persona.indirizzo_residenza.via.descrizione = scene.persona.indirizzo_residenza.via.descrizione.encode('cp1252','utf-8').force_encoding('utf-8')
      # end
      # scene_binding = scene.instance_eval{ binding }
      # cf = persona.codice_fiscale
      # if RUBY_VERSION =~ /1.8/
      #     definitive_file = ERB.new(IO.read(res.path)).result(scene_binding)
      # else
      #     definitive_file = ERB.new(IO.read(res.path).force_encoding('binary')).result(scene_binding)
      # end
    elsif format == :pdf
      # ???
      # template = load_template_from_path(res.path, Demografici)
      # template.init(scene)
      # html = StringIO.new
      # $out.output_to(html) do
      #     template.render
      # end
      # kit = PDFKit.new(html.string, :page_size => 'A4')
      # definitive_file = kit.to_pdf
    elsif format == :odt
      filename_in = "#{Rails.root}/autocertificazioni/odt/#{nome}"
      pathfile = "#{Rails.root}/data/#{result["codiceFiscale"]}/"
      FileUtils.mkpath(pathfile)
      filename_out = pathfile+"#{nome}"

      debug_message("rendering odt #{filename_in} to #{filename_out}", 3)
      render_odt(filename_in, "#{filename_out}")
      if end_format == format
        definitive_file = IO.read("#{filename_out}")                    
      elsif end_format == :pdf
        Docsplit.extract_pdf("#{filename_out}", :output => pathfile) 
        definitive_file = IO.read("#{filename_out}")
      end
    end
    File.open(filename_out, 'r') do |f|
      send_data f.read, type: "application/vnd.oasis.opendocument.text", filename: nome
    end
    # File.delete(file_path)
    # send_file "#{filename_out}", type: "application/vnd.oasis.opendocument.text", x_sendfile: true
    FileUtils.rm_rf(pathfile)
    # File.delete(filename_out) if File.exist?(filename_out)
    # @response.headers['Content-Disposition'] = "attachment; filename=\"#{nome}.#{end_format.to_s}\""
    # @response.headers['Content-Type'] = content_type[end_format]
    # if RUBY_VERSION =~ /1.8/
    #     $out << definitive_file
    # else
    #     $out << definitive_file.force_encoding('BINARY')
    # end  
    # FileUtils.remove_dir(Spider.paths[:data]+"/#{result["codiceFiscale"]}") if File.directory?(Spider.paths[:data]+"/#{result["codiceFiscale"]}")
  end

  # richiesta da portale cittadino
  def aggiorna_richiesta
    # ricevo dal cittadino un aggiornamento di richiesta di certificato
    # ad esempio quando ha pagato un certificato con bollo||segreteria
    # il portale deve inviarmi il tenant

    
  end
  
  def sconosciuto
    render html: '<DOCTYPE html><html><head><title>Pagina non trovata</title></head><body>Pagina non trovata</body></html>'.html_safe
  end
  
  #da fare
  def error_dati
  end
    
  # fa redirect su portale
  def portale
    debug_message("redirecting to "+session[:dominio], 3)
    redirect_to session[:dominio]
    return
  end
    
  # fa redirect su propria anagrafica
  def self
    debug_message("redirecting to "+request.protocol + request.host_with_port + "/dettagli_persona?codice_fiscale=#{session[:cf]}", 3)
    redirect_to request.protocol + request.host_with_port + "/dettagli_persona?codice_fiscale=#{session[:cf]}"
    return
  end

  # va a pulire la sessione e chiama il logout sul portale
  def logout
    url_logout = session['dominio']+"/autenticazione/logout"
    debug_message("redirecting to "+url_logout, 3)
    reset_session
    redirect_to url_logout
    return
  end

  private

  def traccia_operazione(tipologia_richiesta)
    now = Time.now
    operazione = {
      tenant: session[:api_next_tenant],
      obj_created: now,
      obj_modified: now,
      utente_id: session[:user_id],
      ip: request.remote_ip,
      pagina: request.path,
      parametri: Hash[URI.decode_www_form(request.query_string)].to_json, 
      # id_transazione_app: ???, # TODO aggiungere id_transazione_app in traccia
      tipologia_servizio: "Demografici",
      tipologia_richiesta: tipologia_richiesta
    }

    DemograficiTraccium.create(operazione)
  end

  def get_comune(codice, dataEvento)
    comuneString = false
    debug_message("codice: #{codice}", 3)
    debug_message("dataEvento: #{dataEvento}", 3)
    dataEvento = Date.parse dataEvento
    debug_message("dataEvento: #{dataEvento}", 3)
    comune = Comuni.where(codistat: codice).where("dataistituzione <= ? AND datacessazione >= ? ", dataEvento, dataEvento).first
    debug_message(comune, 3)
    if !comune.blank? && !comune.nil?
      comuneString = "#{comune.denominazione_it} (#{comune.siglaprovincia})"
    end
    return comuneString
  end

  def get_stato_estero(codice, dataEvento)
    statoString = false
    debug_message("codice: #{codice}", 3)
    debug_message("dataEvento: #{dataEvento}", 3)
    dataEvento = Date.parse dataEvento
    debug_message("dataEvento: #{dataEvento}", 3)
    stato = StatiEsteri.where(codistat: codice).where("datainiziovalidita <= ? AND datafinevalidita >= ? ", dataEvento, dataEvento).first
    debug_message(stato, 3)
    if !stato.blank? && !stato.nil?
      statoString = "#{stato.denominazione}"
    end
    return statoString
  end

  def is_self
    is_self = false

    if session[:cf_visualizzato].nil? || session[:cf_visualizzato].blank?
      debug_message("is_self setting session[:cf_visualizzato] to #{session[:cf]}", 3)
      session[:cf_visualizzato] = session[:cf]
    end
    
    if session[:cf_visualizzato] == session[:cf]
      is_self = true
    end

    return is_self
  end

  def is_family
    is_family = false

    if session[:cf_visualizzato].nil? || session[:cf_visualizzato].blank?
      debug_message("is_family setting session[:cf_visualizzato] to #{session[:cf]}", 3)
      session[:cf_visualizzato] = session[:cf]
    end
    
    if session[:cf_visualizzato] == session[:cf]
      is_family = true
    else      
      if session[:famiglia].nil?
        session[:famiglia] = []
        session[:famiglia] << session[:cf]
      end
      if session[:famiglia].kind_of?(Array)
        session[:famiglia] = session[:famiglia].to_json
      end
      debug_message(session[:cf_visualizzato],3)
      debug_message(session[:famiglia],3)
      debug_message(JSON.parse(session[:famiglia]),3)
      is_family = session[:cf_visualizzato].in?(JSON.parse(session[:famiglia]))
    end
    return is_family
  end

  def can_see_others
    return PERMESSI[session[:permessi]] != "cittadino"
  end

  def verifica_permessi(azione)
    autorizzato = false

    globale = can_see_others
    cittadino = is_self || is_family

    debug_message("requesting authorization for #{azione} - permissions level is #{PERMESSI[session[:permessi]]}", 3)
    debug_message("globale: #{globale} cittadino: #{cittadino}", 3)

    # il comportamento cambia a seconda se sto visualizzando i dettagli o facendo una ricerca
    # non si sovrascrivono
    if azione == "visualizza_anagrafica"
      if PERMESSI[session[:permessi]] == "ricercare_anagrafiche" # ricerca completa
        autorizzato = globale
      elsif PERMESSI[session[:permessi]] == "ricercare_anagrafiche_no_sensibili" 
        autorizzato = globale
      elsif PERMESSI[session[:permessi]] == "elencare_anagrafiche" # solo elenco ma non si clicca
        autorizzato = false
      elsif PERMESSI[session[:permessi]] == "professionisti" # ricerca ridotta solo nomecognome e cf
        autorizzato = globale
      elsif PERMESSI[session[:permessi]] == "elencare_anagrafiche_certificazione" # ricerca ridotta solo nomecognome e cf, quando visualizza scheda può vedere solo la scheda dei certificati, 
        autorizzato = globale
      elsif PERMESSI[session[:permessi]] == "vedere_solo_famiglia"
        autorizzato = globale # quando entra nella scheda può vedere solo la famiglia e i dati non sensibili
      else
        autorizzato = cittadino # utente cittadino, può vedere solo la sua anagrafica e quelle dei familiari
      end
    elsif azione == "ricerca_anagrafiche"
      autorizzato = globale
    elsif azione == "scarica_certificato"
      autorizzato = cittadino || globale
    end

    return autorizzato
  end

  def carica_variabili_layout

    @nome = session[:nome]
    @demografici_data = { "tipiCertificato" => {}, "esenzioniBollo" => {}, "cittadinanze" => {} }

    tipiCertificato = []
    TipoCertificato.all.each do |tipoCertificato|
      cert = { "id": tipoCertificato.id, "descrizione": tipoCertificato.descrizione }
      tipiCertificato << cert
    end
    @demografici_data["tipiCertificato"] = tipiCertificato

    esenzioniBollo = []
    EsenzioneBollo.all.each do |esenzioneBollo|
      esenzione = { "id": esenzioneBollo.id, "descrizione": esenzioneBollo.descrizione }
      esenzioniBollo << esenzione
    end
    @demografici_data["esenzioniBollo"] = esenzioniBollo

    # cittadinanze = []
    # StatiEsteri.all.each do |stato|
    #   cittadinanza = { "id": stato.id, "descrizione": stato.denominazione }
    #   cittadinanze << cittadinanza
    # end
    # @demografici_data["cittadinanze"] = cittadinanze

    if params["debug"] 
      @demografici_data["test"] = true
    else
      @demografici_data["test"] = false
    end
    
    @demografici_data = @demografici_data.to_json
    @demografici_data = @demografici_data.html_safe
  end

  def get_dominio_sessione_utente
    begin
      # debug_message(session.inspect, 3)
      # reset_session
      #permetto di usare tutti i parametri e li converto in hash
      hash_params = params.permit!.to_hash
      if !hash_params['c_id'].blank? && session[:client_id] != hash_params['c_id']
        reset_session
      end
      if session.blank? || session[:user_id].blank? || false #controllo se ho fatto login
        debug_message("received hash params", 3)
        debug_message(hash_params, 3)
        #se ho la sessione vuota devo ottenere una sessione dal portale
        #se arriva un client_id (parametro c_id) e id_utente lo uso per richiedere sessione
        if !hash_params['c_id'].blank? && !hash_params['u_id'].blank?
          
          #ricavo dominio da oauth2
          url_oauth2_get_info = "https://login.soluzionipa.it/oauth/application/get_info_cid/"+hash_params['c_id']
          #url_oauth2_get_info = "http://localhost:3001/oauth/application/get_info_cid/"+hash_params['c_id'] #PER TEST
          result_info_ente = HTTParty.get(url_oauth2_get_info,
            :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } )
          hash_result_info_ente = result_info_ente.parsed_response
          debug_message("hash_result_info_ente", 3)
          debug_message(hash_result_info_ente, 3)

          @dominio = hash_result_info_ente['url_ente']
          raise "Dominio non censito su applicazioni Oauth" if @dominio.blank?
          #@dominio = "https://civilianext.soluzionipa.it/portal" #per test
          session[:dominio] = @dominio
          #creo jwt per avere sessione utente
          iss = 'demografici.soluzionipa.it'
          if Rails.env.development?
            iss = 'localhost:3000'
          end
          hash_jwt_app = {
            iss: iss, #dominio finale dell'app demografici
            id_app: 'demografici',
            id_utente: hash_params['u_id'],
            sid: hash_params['sid'],
            api_next: true
          }
          debug_message(hash_jwt_app, 3)
          # jwt = JsonWebToken.encode(hash_jwt_app)
          #richiesta in post a get_login_session con authorization bearer
          result = HTTParty.post(@dominio+"/autenticazione/get_login_session.json", 
            :body => hash_params,
            :headers => { 'Authorization' => 'Bearer '+jwt },
            :debug_output => $stdout 
          )
          hash_result = result.parsed_response

          #se ho risultato con stato ok ricavo dati dal portale e salvo in sessione 
          #impostare durata sessione in application.rb: ora dura 30 minuti
          if !hash_result.blank? && !hash_result["stato"].nil? && hash_result["stato"] == 'ok'
            jwt_data = JsonWebToken.decode(hash_result['token'])

            # inserisco dati in sessione uno per uno per evitare conversione oggetti e cookie overflow
            # debug_message(jwt_data, 3)
            session[:user_id] = jwt_data["id"]
            session[:permessi] = PERMESSI.find_index(jwt_data["permessi"]) # uso un indice numerico per ridurre la dimensione del cookie
            session[:user_sid] = jwt_data["sid"]
            session[:nome] = jwt_data[:nome]
            session[:cognome] = jwt_data[:cognome]
            session[:cf] = jwt_data[:cf]
            session[:data_nascita] = jwt_data["data_nascita"]
            session[:tipo_documento] = jwt_data["tipo_documento"]
            session[:numero_documento] = jwt_data["numero_documento"]
            session[:data_documento] = jwt_data["data_documento"]
            session[:api_next_tenant] = jwt_data["api_next"]["tenant"]
            session[:api_next_client_id] = jwt_data["api_next"]["client_id"]
            session[:api_next_secret] = jwt_data["api_next"]["secret"]
            session[:client_id] = hash_params['c_id']
            session[:famiglia] = []

            # TODO gestire meglio il dominio, aspettiamo setup a db
            solo_dom = @dominio.gsub("/portal","")
            
          else
            #se ho problemi ritorno su portale con parametro di errore
            unless @dominio.blank?
              debug_message("redirecting to "+@dominio+"/?err", 3)
              redirect_to @dominio+"/?err"
              return
            else
              debug_message("redirecting to "+sconosciuto, 3)
              redirect_to sconosciuto
              return   
            end
            
          end
        else

          unless @dominio.blank?
            #mando a fare autenticazione sul portal
              debug_message("redirecting to "+@dominio+"/autenticazione", 3)
            redirect_to @dominio+"/autenticazione"
            return
          else
            debug_message("redirecting to "+sconosciuto, 3)
            redirect_to sconosciuto
            return    
          end

        end

      else
        @dominio = session[:dominio] || "dominio non presente"
      end
    rescue => exc
      logger.error exc.message
      logger.error exc.backtrace.join("\n")
    end
  end

  def get_layout_portale
    #ricavo l'hash del layout
    result = HTTParty.get(session[:dominio]+"/get_hash_layout.json", 
      :body => {})
    hash_result = result.parsed_response
    ritornato_hash = false
    if hash_result['esito'] == 'ok'
      ritornato_hash = true
    else
      logger.error "Portale cittadino #{session[:dominio]} non raggiungibile per ottenere hash di layout! Rifaccio chiamata per possibili problemi con Single Thread"
      i = 0
      while ritornato_hash == false && i < 10 
        sleep 1
        result = HTTParty.get(session[:dominio]+"/get_hash_layout.json", 
          :body => {})
        hash_result = result.parsed_response
        if hash_result['esito'] == 'ok'
          ritornato_hash = true
        end
      end
    end  

    if ritornato_hash
        hash_layout = hash_result['hash']
        nome_file = "#{session[:client_id]}_#{hash_layout}.html.erb"
        session[:nome_file_layout] = nome_file
        #cerco if file di layout se presente uso quello
        if Dir["#{Rails.root}/app/views/layouts/layout_portali/#{session[:client_id]}_#{hash_layout}.*"].length == 0
            #scrivo il file
            #cancello i vecchi file con stesso client_id (della stesa installazione)
            Dir["#{Rails.root}/app/views/layouts/layout_portali/#{session[:client_id]}_*"].each{ |vecchio_layout|
              File.delete(vecchio_layout) 
            }
            #richiedo il layout dal portale, questa non dovrebbe avere problemi di single thread in quanto va a prendere html da sessione sul portale
            result = HTTParty.get(session[:dominio]+"/get_html_layout.json", :body => {})
            hash_result = result.parsed_response
            html_layout = Base64.decode64(hash_result['html'])
            #Aggiungo variabile per disabilitare Function.prototype.bind in portal.x.js
            js_da_iniettare = '<script type="text/javascript">window.appType = "external";</script>'
            #Devo iniettare nel layout gli assets e lo yield
            head_da_iniettare = "<%= csrf_meta_tags %>
            <%= csp_meta_tag %>
            <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>"
            html_layout = html_layout.gsub("</head>", head_da_iniettare+"</head>").gsub("id=\"portal_container\">", "id=\"portal_container\"><%=yield%>")
            html_layout = html_layout.sub("<script",js_da_iniettare+" <script")
            html_layout = html_layout.gsub("</body>","<script type='text/javascript'>var demograficiData = <%=@demografici_data%>;</script></body>")
            html_layout = html_layout.gsub("</body>","<span class='hidden' id='nome_utente'><%=@nome%></span></body>")
            #codice js comune a tutte le pagine
            html_layout = html_layout.gsub("</body>","<%= javascript_pack_tag 'demografici' %> </body>")
            #parte che include il js della parte react sul layout CHE VA ALLA FINE, ALTRIMENTI REACT NON VA
            html_layout = html_layout.gsub("</body>","<%= javascript_pack_tag @page_app %> </body>")
            path_dir_layout = "#{Rails.root}/app/views/layouts/layout_portali/"
            File.open(path_dir_layout+nome_file, "w") { |file| file.puts(html_layout.force_encoding(Encoding::UTF_8).encode(Encoding::UTF_8)) }
        end
    else
      debug_message("redirecting to "+session[:dominio]+"/?err=no_hash", 3)
      redirect_to session[:dominio]+"/?err=no_hash"
      return
    end
  end

  def test_variables
    session[:permessi]=PERMESSI.find_index("ricercare_anagrafiche")
    # session[:permessi]=PERMESSI.find_index("ricercare_anagrafiche_no_sensibili")
    # session[:permessi]=PERMESSI.find_index("elencare_anagrafiche")
    # session[:permessi]=PERMESSI.find_index("professionisti")
    # session[:permessi]=PERMESSI.find_index("elencare_anagrafiche_certificazione")
    # session[:permessi]=PERMESSI.find_index("vedere_solo_famiglia")
    # session[:permessi]=PERMESSI.find_index("cittadino")
  end

  def debug_message(message, level)
    # puts "debug_message called for message #{message} and level #{level} @@log_level #{@@log_level} @@log_to_file #{@@log_to_file}"
    if level <= @@log_level
      logger.debug message unless !@@log_to_file
      puts message unless !@@log_to_output
    end
  end

end
