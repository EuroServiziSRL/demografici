require 'httparty'
require 'uri'
require "base64"
require 'openssl'

## auth su api
# https://login.microsoftonline.com/97d6a602-2492-4f4c-9585-d2991eb3bf4c/oauth2/token
# L’ambiente di Test su UAT è UAT281: ( DEDA UAT281 - DEMO DEMOGRAFIA 2 – id 348 )
# Application ID:
# aebe50cd-bbc0-4bf5-94ba-4e70590bcf1a
# Secret:
# w9=jyc0bA.sBVLX@aHD:87lPZlS4r=7x

class ApplicationController < ActionController::Base
  include ApplicationHelper
  # TODO aggiungere anche resource in config?
  # @@api_resource = "https://api.civilianextuat.it"
  @@api_resource = "https://api.civilianextdev.it"
  @@api_url = "#{@@api_resource}/Demografici/"
  before_action :get_dominio_sessione_utente, :get_layout_portale, :carica_variabili_layout
  
  #ROOT della main_app
  def index
    # session[:cf] = 'ZMMRHG87L05Z600V'
    # session[:client_id] = 768

    # 
    #carico cf in variabile per usarla sulla view
    puts "index - session[:cf]: "+session[:cf]
    puts "index - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s
    @cf_utente_loggato = session[:cf]
    @page_app = "dettagli_persona"
     
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"

  end

  def dettagli_persona
    puts "dettagli_persona - session[:cf]: "+session[:cf]
    puts "dettagli_persona - params[\"codice_fiscale\"]: "+params["codice_fiscale"]
    puts "dettagli_persona - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s
    @page_app = "dettagli_persona"

    if params["codice_fiscale"] == session[:cf]
      session[:cf_visualizzato] = nil
      puts "session[:cf_visualizzato] set to null"
    else
      session[:cf_visualizzato] = params["codice_fiscale"]
      puts "session[:cf_visualizzato] now is: "+session[:cf_visualizzato].to_s
    end
    puts "session is:"
    puts session.class.inspect
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
    # TODO implementare recupero diritti segreteria da api quando sarà disponibile
    if cartaLibera || esenzioneBollo
      importo_bollo = 0 # importo bollo è 0 su carta libera o se è specificata esenzione
    else
      importo_bollo = 16 # altrimenti è 16 (importo fisso)
    end
    
    # TODO recuperare diritti segreteria da api quando sarà disponibile
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
      # TODO aggiungere importo quando l'api lo fornirà
      # diritti_importo: importo_segreteria,
      diritti_importo: 0, # per ora sempre a 0 perchè non cè l'api
      # TODO aggiungere uso 
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

    # session[:cf_visualizzato] = params["codice_fiscale"]
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
  end
  
  def authenticate  
    puts "authenticate - session[:cf]: "+session[:cf]
    puts "authenticate - params[\"codice_fiscale\"]: "+params["codice_fiscale"].to_s
    puts "authenticate - session[:cf_visualizzato]: "+session[:cf_visualizzato].to_s
    requestParams = {
      "resource": "#{@@api_resource.sub("https","http")}", 
      "tenant": "#{session[:api_next_tenant]}",
      "client_id": "#{session[:api_next_client_id]}",
      "client_secret": "#{session[:api_next_secret]}",
      "grant_type": 'client_credentials'
    }

    # params["tenant"] = '97d6a602-2492-4f4c-9585-d2991eb3bf4c'
    # params["client_id"] = 'aebe50cd-bbc0-4bf5-94ba-4e70590bcf1a'
    # params["client_secret"] = 'w9=jyc0bA.sBVLX@aHD:87lPZlS4r=7x'
    # puts params

    
    oauthURL = "https://login.microsoftonline.com/#{requestParams[:tenant]}/oauth2/token";
    # puts oauthURL
    result = HTTParty.post(oauthURL, 
      :body => requestParams.to_query,
      :headers => { 'Content-Type' => 'application/x-www-form-urlencoded','Accept' => 'application/json'  } ,
      :debug_output => $stdout
    )

    if !result["access_token"].nil? && result["access_token"].length > 0
      puts "setting token into session"
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
    puts "ricerca_anagrafiche_individui"
    puts params

    page = params[:page]
    if page.nil? || page.blank?
      page = 1
    end

    # TODO aggiungere wildcard ad altri campi ricerca e verificare che nomeCognome funzioni
    if !params[:nomeCognome].nil? || !params[:nomeCognome].blank?
      params[:nomeCognome] = "%#{params[:nomeCognome]}%"
    end
    # params[:MostraIndirizzo] = true
    # params[:MostraMaternita] = true
    # params[:MostraConiuge] = true
    # params[:MostraDatidecesso] = true
    # params[:MostraCartaIdentita] = true
    # params[:MostraTitoloSoggiorno] = true
    # params[:MostraProfessione] = true
    # params[:MostraTitoloStudio] = true
    # params[:MostraPatente] = true
    # params[:MostraVeicoli] = true
    # params[:MostraDatiStatoCivile] = true
    # params[:itemsPerPage] = 100
    # params[:pageNumber] = 4

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
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )   
      result = JSON.parse(result.response.body)
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
    
    # puts "query string for sha1 is [#{queryString.strip}]"
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
    
    puts "ricerca_individui - logged user cf: "+session[:cf]
    puts "ricerca_individui - cf_visualizzato: "+session[:cf_visualizzato].to_s
    puts "ricerca_individui - \"cf_visualizzato\": "+session["cf_visualizzato"].to_s

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
      # params = { "codiceFiscale": "ZNNCDD51P20C794V" } # pochi dati
      # params = { "codiceFiscale": "TLLLRA56E46B153E" } # deceduta, no famiglia
      # params = { "codiceFiscale": "RGTVRB33C53B153U" }
      # params = { "codiceFiscale": "GRFJNU74M26Z148Q" }
      # params = { "codiceFiscale": "DPLKTY68L54Z140P" }
      searchParams = { "CodiceFiscale": cf_ricerca }

      # TODO capire quali sono dati sensibili - vedere in codice demografici

      nascondi_sensibili = !is_self && session[:permessi].include?("ricercare_anagrafiche_no_sensibili")

      puts "is_self? "+is_self.to_s
      puts 'session[:permessi].include?("ricercare_anagrafiche_no_sensibili")? '+session[:permessi].include?("ricercare_anagrafiche_no_sensibili").to_s
      puts 'nascondi_sensibili? '+nascondi_sensibili.to_s

      if !nascondi_sensibili
        searchParams[:MostraIndirizzo] = true
        searchParams[:MostraDatiMaternita] = true
        searchParams[:MostraDatiPaternita] = true
        searchParams[:MostraConiuge] = true
        searchParams[:MostraDatiDecesso] = true
        searchParams[:MostraDatiCartaIdentita] = true
        searchParams[:MostraDatiTitoloSoggiorno] = true
        searchParams[:MostraDatiProfessione] = true
        searchParams[:MostraDatiTitoloStudio] = true
        searchParams[:MostraDatiPatenti] = true
        searchParams[:MostraDatiVeicoli] = true
        searchParams[:MostraDatiStatoCivile] = true
      end

      puts "searchParams: "
      puts searchParams

      result = HTTParty.post(
        "#{@@api_url}/Anagrafe/RicercaIndividui?v=1.0", 
        :body => searchParams.to_json,
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )    
      # result = result.response.body
      result = JSON.parse(result.response.body)
      result = result[0]
      if !result.nil? && result.length > 0

        result["datiRichiedente"] = {
          "nome": session[:nome], 
          "cognome": session[:cognome], 
          "cf": session[:cf], 
          "data_nascita": session[:data_nascita], 
          "tipo_documento": session[:tipo_documento], 
          "numero_documento": session[:numero_documento], 
          "data_documento": session[:data_documento], 
        }

        puts "datiRichiedente set to"
        puts result["datiRichiedente"]

        if nascondi_sensibili
          result = {
            "nome":result["nome"],
            "cognome":result["cognome"],
            "dataNascita":result["dataNascita"]
          }
        end

        comune = get_comune(result["codiceIstatComuneNascitaItaliano"], result["dataNascita"])
        puts "comune: #{comune}"
        if !comune.blank? && !comune.nil? && comune
          result["comuneNascitaDescrizione"] = comune
        elsif !result["descrizioneComuneNascitaEstero"].blank?
          stato = get_stato_estero(result["codiceIstatNazioneNascitaEstero"], result["dataNascita"])
          result["comuneNascitaDescrizione"] = result["descrizioneComuneNascitaEstero"]+" (#{stato})"
        else
          result["comuneNascitaDescrizione"] = "";
        end

        if !nascondi_sensibili
          searchParams = { 
            "codiceAggregazione": result["codiceFamiglia"], 
          }
          resultFamiglia = HTTParty.post(
            "#{@@api_url}/Anagrafe/RicercaComponentiFamiglia?v=1.0", 
            :body => searchParams.to_json,
            :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "bearer #{session[:token]}" } ,
            :debug_output => $stdout
          )    
          resultFamiglia = JSON.parse(resultFamiglia.response.body)
          famiglia = []
          session[:famiglia] = []
          resultFamiglia.each do |componente|
            puts "looping through resultFamiglia, componente:"
            puts componente
            relazione = RelazioniParentela.where(id_relazione: componente["codiceRelazioneParentelaANPR"]).first
            componente["relazioneParentela"] = relazione.descrizione
            session[:famiglia] << componente["codiceFiscale"]
            famiglia << componente
          end
          result["famiglia"] = famiglia
          result["csrf"] = form_authenticity_token

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
              puts "data inserimento"
              puts richiesta_certificato.data_inserimento
              puts "180.days.ago"
              puts 180.days.ago

              if 180.days.ago >= richiesta_certificato.data_inserimento
                scaduto = true
              end
              
              if !scaduto && richiesta_certificato.stato == "da_pagare"
                statoPagamenti = stato_pagamento("#{session[:dominio].gsub("https","http")}/servizi/pagamenti/ws/stato_pagamenti",richiesta_certificato.id)
                if(!statoPagamenti.nil? && statoPagamenti["esito"]=="ok" && (statoPagamenti["esito"][0]["stato"]=="Pagato"))
                  # pagato, lascio scaricare il documento
                  url = "/scarica_certificato?file=#{richiesta_certificato.documento.gsub('./','')}"
                else                  
                  url = "#{session[:dominio]}/servizi/pagamenti/"
                  puts statoPagamenti
                  puts statoPagamenti["esito"]
                  if(statoPagamenti.nil? || statoPagamenti["esito"]!="ok")
                    puts "statoPagamenti NOT OK"
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
                      
                      # puts "query string for sha1 is [#{queryString.strip}]"
                      # queryString = "importo=#{value["importoResiduo"].gsub(',', '.')}&descrizione=#{value["codiceAvvisoDescrizione"]} - n.#{value["numeroAvviso"]}&codice_applicazione=tributi&url_back=#{request.original_url}&idext=#{value["idAvviso"]}&tipo_elemento=pagamento_tari&nome_versante=#{session[:nome]}&cognome_versante=#{session[:cognome]}&codice_fiscale_versante=#{session[:cf]}&nome_pagatore=#{session[:nome]}&cognome_pagatore=#{session[:cognome]}&codice_fiscale_pagatore=#{session[:cf]}"
                      fullquerystring = URI.unescape(queryString)
                      # qs = fullquerystring.sub(/&hqs=\w*/,"").strip+"3ur0s3rv1z1"
                      qs = queryString+"3ur0s3rv1z1"
                      hqs = OpenSSL::Digest::SHA1.new(qs)
                      url = "#{session[:dominio]}/servizi/pagamenti/aggiungi_pagamento_pagopa.json?#{queryString}&hqs=#{hqs}&id_utente=#{session[:user_id]}&sid=#{session[:user_sid]}"
                    end
                  else
                    puts "statoPagamenti OK"
                  end
                end
              elsif !scaduto && richiesta_certificato.stato == "pagato"
                url = "/scarica_certificato?file=#{richiesta_certificato.documento.gsub('./','')}"
              else
                url = ""
              end
              # TODO scaricabile solo una volta, vedere su velletri o giugliano, aggiungere avviso
              # TODO prevedere scadenza 180gg, se stato scaduto si vede ma non si scarica più
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

    # puts "ricerca individui done, tracking request"
    traccia_operazione(tipologia_richiesta)
    # puts "request tracked, result is:"
    # puts result

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
    
  #Va a pulire la sessione e chiama il logout sul portale
  def logout
    url_logout = File.join(session['dominio'],"autenticazione/logout")
    reset_session
    redirect_to url_logout
  end

  private

  def traccia_operazione(tipologia_richiesta)
    # TODO implementare su: visualizzazione scheda anagrafica e richiesta certificato, togliere da download certificato
    now = Time.now
    operazione = {
      # tenant: session[:tenant],#TODO aggiungere tenant in traccia
      obj_created: now,
      obj_modified: now,
      utente_id: session[:user_id],
      ip: request.remote_ip,
      pagina: request.path,
      parametri: request.query_string, # TODO questo dev'essere un json non un query string
      # id_transazione_app: ???, # TODO aggiungere id_transazione_app in traccia
      tipologia_servizio: "Demografici",
      tipologia_richiesta: tipologia_richiesta
    }

    DemograficiTraccium.create(operazione)
  end

  def get_comune(codice, dataEvento)
    comuneString = false
    puts "codice: #{codice}"
    puts "dataEvento: #{dataEvento}"
    dataEvento = Date.parse dataEvento
    puts "dataEvento: #{dataEvento}"
    comune = Comuni.where(codistat: codice).where("dataistituzione <= ? AND datacessazione >= ? ", dataEvento, dataEvento).first
    puts comune
    if !comune.blank? && !comune.nil?
      comuneString = "#{comune.denominazione_it} (#{comune.siglaprovincia})"
    end
    return comuneString
  end

  def get_stato_estero(codice, dataEvento)
    statoString = false
    puts "codice: #{codice}"
    puts "dataEvento: #{dataEvento}"
    dataEvento = Date.parse dataEvento
    puts "dataEvento: #{dataEvento}"
    stato = StatiEsteri.where(codistat: codice).where("datainiziovalidita <= ? AND datafinevalidita >= ? ", dataEvento, dataEvento).first
    puts stato
    if !stato.blank? && !stato.nil?
      statoString = "#{stato.denominazione}"
    end
    return statoString
  end

  def is_self
    is_self = false

    if session[:cf_visualizzato].nil? || session[:cf_visualizzato].blank?
      puts "is_self setting session[:cf_visualizzato] to #{session[:cf]}"
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
      puts "is_family setting session[:cf_visualizzato] to #{session[:cf]}"
      session[:cf_visualizzato] = session[:cf]
    end
    
    if session[:cf_visualizzato] == session[:cf]
      is_family = true
    else      
      if session[:famiglia].nil?
        session[:famiglia] = []
        session[:famiglia] << session[:cf]
      end
      is_family = session[:cf_visualizzato].in?(session[:famiglia])
    end
    return is_family
  end

  def can_see_others
    return session[:permessi].include?("ricercare_anagrafiche") || session[:permessi].include?("ricercare_anagrafiche_no_sensibili") || session[:permessi].include?("elencare_anagrafiche") || session[:permessi].include?("professionisti")
  end

  def verifica_permessi(azione)
    autorizzato = false
    
    # TODO test rimuovere
    session[:permessi] = ["vedere_solo_famiglia","elencare_anagrafiche"]

    # il comportamento cambia a seconda se sto visualizzando i dettagli o facendo una ricerca
    # TODO quali sovrascrivono quali?
    if azione == "visualizza_anagrafica"
      if session[:permessi].include?("ricercare_anagrafiche") # TODO ricerca completa
        autorizzato = can_see_others
      elsif session[:permessi].include?("ricercare_anagrafiche_no_sensibili") 
        # TODO sovrascrive ricercare_anagrafiche se presente?
        autorizzato = can_see_others
      elsif session[:permessi].include?("elencare_anagrafiche") # TODO solo elenco ma non si clicca
        autorizzato = can_see_others
      elsif session[:permessi].include?("professionisti") # TODO ricerca ridotta solo nomecognome e cf
        autorizzato = can_see_others
      elsif session[:permessi].include?("professionisti_limitato") # TODO ricerca ridotta solo nomecognome e cf ma quando visualizza scheda può vedere solo la scheda dei certificati, da aggiungere tra i profili portal
        autorizzato = can_see_others
      elsif session[:permessi].include?("vedere_solo_famiglia") 
        autorizzato = is_self || is_family # l'utente può vedere solo la sua anagrafica e le anagrafiche dei familiari
      else
        autorizzato = is_self # l'utente può vedere solo la sua anagrafica
      end
    elsif azione == "ricerca_anagrafiche"
      autorizzato = is_self || is_family || can_see_others
    elsif azione == "scarica_certificato"
      autorizzato = is_self || is_family || can_see_others
    end

    return autorizzato
  end

  def carica_variabili_layout
    @nome = session[:nome]
    @demografici_data = { "tipiCertificato" => {}, "esenzioniBollo" => {}  }

    # tipiCertificato = []
    # TipoCertificato.all.each do |tipoCertificato|
    #   cert = { "id": tipoCertificato.id, "descrizione": tipoCertificato.descrizione }
    #   tipiCertificato << cert
    # end
    # @tipiCertificato = tipiCertificato.to_json

    # esenzioniBollo = []
    # EsenzioneBollo.all.each do |esenzioneBollo|
    #   esenzione = { "id": esenzioneBollo.id, "descrizione": esenzioneBollo.descrizione }
    #   esenzioniBollo << esenzione
    # end
    # @esenzioniBollo = esenzioniBollo.to_json

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
      # puts session.inspect
      # reset_session
      #permetto di usare tutti i parametri e li converto in hash
      hash_params = params.permit!.to_hash
      if !hash_params['c_id'].blank? && session[:client_id] != hash_params['c_id']
        reset_session
      end
      if session.blank? || session[:user_id].blank? || false #controllo se ho fatto login
        puts "received hash params"
        puts hash_params
        #se ho la sessione vuota devo ottenere una sessione dal portale
        #se arriva un client_id (parametro c_id) e id_utente lo uso per richiedere sessione
        if !hash_params['c_id'].blank? && !hash_params['u_id'].blank?
          
          #ricavo dominio da oauth2
          url_oauth2_get_info = "https://login.soluzionipa.it/oauth/application/get_info_cid/"+hash_params['c_id']
          #url_oauth2_get_info = "http://localhost:3001/oauth/application/get_info_cid/"+hash_params['c_id'] #PER TEST
          result_info_ente = HTTParty.get(url_oauth2_get_info,
            :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } )
          hash_result_info_ente = result_info_ente.parsed_response
          puts "hash_result_info_ente"
          puts hash_result_info_ente

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
          puts hash_jwt_app
          jwt = JsonWebToken.encode(hash_jwt_app)
          # TODO aggiungere permessi e info documento
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
            # puts jwt_data
            session[:user_id] = jwt_data["id"]
            session[:permessi] = jwt_data["permessi"]
            session[:user_sid] = jwt_data["sid"]
            session[:nome] = jwt_data[:nome]
            session[:cognome] = jwt_data[:cognome]
            session[:cf] = jwt_data[:cf]
            session[:user_sid] = jwt_data["sid"]
            session[:data_nascita] = jwt_data["data_nascita"]
            session[:tipo_documento] = jwt_data["tipo_documento"]
            session[:numero_documento] = jwt_data["numero_documento"]
            session[:data_documento] = jwt_data["data_documento"]
            session[:api_next_tenant] = jwt_data["api_next"]["tenant"]
            session[:api_next_client_id] = jwt_data["api_next"]["client_id"]
            session[:api_next_secret] = jwt_data["api_next"]["secret"]
            session[:client_id] = hash_params['c_id']
            session[:famiglia] = []

            # puts session.inspect

            # session[:user] = jwt_data #uso questo oggetto per capire se utente connesso!
            # puts "received user data hash"
            # puts jwt_data
            # puts "received cf is "+jwt_data[:cf]
            # session[:cf] = jwt_data[:cf]
            # @nome = jwt_data[:nome] 
            # @cognome = jwt_data[:cognome]
            # session[:client_id] = hash_params['c_id']
            # session[:tipo_documento] = jwt_data[:tipo_documento]
            # session[:numero_documento] = jwt_data[:numero_documento]
            # session[:data_documento] = jwt_data[:data_documento]
            # session[:data_nascita] = "" # TODO recuperare da portal
            # session[:tenant] = jwt_data[:api_next][:tenant]
            # TODO gestire meglio il dominio, aspettiamo setup a db
            solo_dom = @dominio.gsub("/portal","")
            
          else
            #se ho problemi ritorno su portale con parametro di errore
            unless @dominio.blank?
              redirect_to @dominio+"/?err"
              return
            else
              redirect_to sconosciuto
              return   
            end
            
          end
        else

          unless @dominio.blank?
            #mando a fare autenticazione sul portal
            redirect_to @dominio+"/autenticazione"
            return
          else
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
            File.open(path_dir_layout+nome_file, "w") { |file| file.puts html_layout.force_encoding(Encoding::UTF_8).encode(Encoding::UTF_8) }
        end
    else
      redirect_to session[:dominio]+"/?err=no_hash"
    
    end
  end


end
