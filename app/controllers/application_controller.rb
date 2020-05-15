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
  @@api_resource = "https://api.civilianextuat.it"
  @@api_url = "#{@@api_resource}/Demografici/"
  before_action :get_dominio_sessione_utente, :get_layout_portale, :carica_variabili_layout
  
  #ROOT della main_app
  def index
    # 
    #carico cf in variabile per usarla sulla view
    puts "logged user cf: "+session[:cf]
    # puts "cf interrogazione: "+session[:interroga_cf]
    @cf_utente_loggato = session[:cf]
    @page_app = "dettagli_persona"
     
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"

  end

  def dettagli_persona
    puts "logged user cf: "+session[:cf]
    @page_app = "dettagli_persona"

    if params["codice_fiscale"] == session[:cf]
      session[:interroga_cf] = nil
    else
      session[:interroga_cf] = params["codice_fiscale"]
      puts "cf interrogazione: "+session[:interroga_cf].to_s
    end
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
    if !session[:interroga_cf].nil? &&! session[:interroga_cf].blank? 
      cf_certificato = session[:interroga_cf]
    end

    @page_app = "richiedi_certificato"

    nome_certificato = ""
    tipo_certificato = TipoCertificato.find_by_id(params[:tipoCertificato])  
    if !tipo_certificato.blank? || !tipo_certificato.nil?
      nome_certificato = tipo_certificato.descrizione
    end

    # TODO da dove prendiamo questi importi?
    importo_bollo = rand(1.2...16.9).round(1)
    puts "importo_bollo: "+importo_bollo.to_s
    importo_segreteria = 0

    if !params[:esenzioneBollo].nil? && !params[:esenzioneBollo].blank? &&  params[:esenzioneBollo] != "0"
      puts "esenzione bollo"
      importo_bollo = 0
    end

    if rand(2)>0
      importo_segreteria = rand(5...20).round(1)
    end

    certificato = {
      tenant: "97d6a602-2492-4f4c-9585-d2991eb3bf4c",
      codice_fiscale: cf_certificato,
      codici_certificato: [params[:tipoCertificato].to_i],
      bollo: importo_bollo,
      bollo_esenzione: params[:esenzioneBollo],
      nome_certificato: nome_certificato,
      # TODO aggiungere importo e uso
      diritti_importo: importo_segreteria,
      # uso: "",
      richiedente_cf: session[:cf],
      richiedente_nome: session[:nome],
      richiedente_cognome: session[:cognome],
      # TODO aggiungere dati documento e data nascita
      # richiedente_doc_riconoscimento: ( richiedente_diverso ? nil : docs[richiedente_random] ),
      # richiedente_doc_data: ( richiedente_diverso ? nil : rand_time(5.years.ago, 30.days.ago) ),
      # richiedente_data_nascita: ( richiedente_diverso ? nil : rand_time(80.years.ago,18.years.ago) ),
      # richiesta: "", # non usato
      stato: "nuovo",
      # data_inserimento: "", # data inserimento del certificato che verrà inserito dall'ente
      data_prenotazione: Time.now,
      email: session[:email],
      id_utente: session["user"]["id"],
      # documento: "", # il certificato che verrà inserito dall'ente
    }

    Certificati.create(certificato)    

    # session[:interroga_cf] = params["codice_fiscale"]
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
  end

  def ricerca_anagrafiche
    @page_app = "richiedi_certificato"
    @nome = session[:user]["nome"]

    # session[:interroga_cf] = params["codice_fiscale"]
    render :template => "application/index" , :layout => "layout_portali/#{session[:nome_file_layout]}"
  end
  
  def authenticate  
    params = {
      "resource": "#{@@api_resource.sub("https","http")}", 
      "tenant": "#{session[:user]["api_next"]["tenant"]}",
      "client_id": "#{session[:user]["api_next"]["client_id"]}",
      "client_secret": "#{session[:user]["api_next"]["secret"]}",
      "grant_type": 'client_credentials'
    }

    # params["tenant"] = '97d6a602-2492-4f4c-9585-d2991eb3bf4c'
    # params["client_id"] = 'aebe50cd-bbc0-4bf5-94ba-4e70590bcf1a'
    # params["client_secret"] = 'w9=jyc0bA.sBVLX@aHD:87lPZlS4r=7x'
    # puts params

    
    oauthURL = "https://login.microsoftonline.com/#{params[:tenant]}/oauth2/token";
    # puts oauthURL
    result = HTTParty.post(oauthURL, 
      :body => params.to_query,
      :headers => { 'Content-Type' => 'application/x-www-form-urlencoded','Accept' => 'application/json'  } ,
      :debug_output => $stdout
    )

    if !result["access_token"].nil? && result["access_token"].length > 0
      session[:token] = result["access_token"]
    end
    
    # result["url"] = oauthURL
    # result["params"] = params

    render :json => result
  end  

  def ricerca_individui
    
    puts "logged user cf: "+session[:cf]
    cf_ricerca = session[:interroga_cf]
    if session[:interroga_cf].nil? || session[:interroga_cf].blank? 
      cf_ricerca = session[:cf]
    elsif session[:interroga_cf] == session[:cf]
      cf_ricerca = session[:cf]
    end
    # puts "cf interrogazione: "+session[:interroga_cf]
    # params = { "mostraDatiIscrizione": "true",  "codiceFiscale": "#{session[:cf]}", "nomeCognome": "#{session[:nome]} #{session[:cognome]}" }
    # params = { "mostraDatiIscrizione": "true",  "codiceFiscale": "ZNNCDD51P20C794V", "nomeCognome": "CANDIDO ZANONI" }
    # params = { "codiceFiscale": "ZNNCDD51P20C794V" } # pochi dati
    # params = { "codiceFiscale": "TLLLRA56E46B153E" } # deceduta, no famiglia
    # params = { "codiceFiscale": "RGTVRB33C53B153U" }
    # params = { "codiceFiscale": "GRFJNU74M26Z148Q" }
    # params = { "codiceFiscale": "DPLKTY68L54Z140P" }
    params = { "codiceFiscale": cf_ricerca }

    params[:mostraMaternita] = true
    params[:mostraConiuge] = true
    params[:mostraDatidecesso] = true
    params[:mostraCartaIdentita] = true
    params[:mostraTitoloSoggiorno] = true
    params[:mostraProfessione] = true
    params[:mostraTitoloStudio] = true
    params[:mostraPatente] = true
    params[:mostraVeicoli] = true
    params[:mostraDatiStatoCivile] = true

    puts params

    result = HTTParty.post(
      "#{@@api_url}/Anagrafe/RicercaIndividui?v=1.0", 
      :body => params.to_json,
      :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "bearer #{session[:token]}" } ,
      :debug_output => $stdout
    )    
    # result = result.response.body
    result = JSON.parse(result.response.body)
    result = result[0]
    if !result.nil? && result.length > 0
      comune = Comuni.where(codistat: result["codiceIstatComuneNascitaItaliano"]).first
      puts comune
      # TODO aggiungere tabella stati esteri e recuperare stato nascita come comune nascita ita
      if !comune.blank? && !comune.nil?
        result["comuneNascitaDescrizione"] = comune.denominazione_it
      elsif !result["descrizioneComuneNascitaEstero"].blank?
        result["comuneNascitaDescrizione"] = result["descrizioneComuneNascitaEstero"]+" ("+result["codiceIstatNazioneNascitaEstero"]+")"
      else
        result["comuneNascitaDescrizione"] = "";
      end
      # session[:cf] = result["codiceFiscale"]
      params = { 
        "codiceAggregazione": result["codiceFamiglia"], 
        # "codiceFiscaleComponente": result["codiceFiscale"] # non li mostra tutti se metto cf
      }
      resultFamiglia = HTTParty.post(
        "#{@@api_url}/Anagrafe/RicercaComponentiFamiglia?v=1.0", 
        :body => params.to_json,
        :headers => { 'Content-Type' => 'application/json','Accept' => 'application/json', 'Authorization' => "bearer #{session[:token]}" } ,
        :debug_output => $stdout
      )    
      resultFamiglia = JSON.parse(resultFamiglia.response.body)
      famiglia = []
      resultFamiglia.each do |componente|
        puts "looping through resultFamiglia, componente:"
        puts componente
        relazione = RelazioniParentela.where(id_relazione: componente["codiceRelazioneParentelaANPR"]).first
        componente["relazioneParentela"] = relazione.descrizione
        famiglia << componente
      end
      result["famiglia"] = famiglia
      result["csrf"] = form_authenticity_token

      result["certificati"] = []
      result["richiesteCertificati"] = []

      puts cf_ricerca
      puts session[:cf]
      if cf_ricerca == session[:cf]
        searchParams = {}
        searchParams[:tenant] = session[:user]["api_next"]["tenant"]
        searchParams[:id_utente] = session["user"]["id"]
        puts searchParams
        richieste_certificati = Certificati.where("tenant = :tenant AND id_utente = :id_utente", searchParams)
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
            
            if richiesta_certificato.stato == "da_pagare"
              statoPagamenti = stato_pagamento("#{session[:dominio].gsub("https","http")}/servizi/pagamenti/ws/stato_pagamenti",richiesta_certificato.id)
              if(!statoPagamenti.nil? && statoPagamenti["esito"]=="ok" && (statoPagamenti["esito"][0]["stato"]=="Pagato"))
                # pagato, lascio scaricare il documento
              else
                date = richiesta_certificato.data_inserimento
                formatted_date = date.strftime('%d/%m/%Y')
                
                parametri = {
                  importo: "#{importo}",
                  descrizione: "#{richiesta_certificato.nome_certificato} - n.#{richiesta_certificato.id}",
                  codice_applicazione: "demografici", # TODO va bene questo codice applicazione?
                  url_back: request.protocol + request.host_with_port,
                  idext: richiesta_certificato.id,
                  tipo_elemento: "certificato",
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
                
  #               puts "query string for sha1 is [#{queryString.strip}]"
  #               queryString = "importo=#{value["importoResiduo"].gsub(',', '.')}&descrizione=#{value["codiceAvvisoDescrizione"]} - n.#{value["numeroAvviso"]}&codice_applicazione=tributi&url_back=#{request.original_url}&idext=#{value["idAvviso"]}&tipo_elemento=pagamento_tari&nome_versante=#{session[:nome]}&cognome_versante=#{session[:cognome]}&codice_fiscale_versante=#{session[:cf]}&nome_pagatore=#{session[:nome]}&cognome_pagatore=#{session[:cognome]}&codice_fiscale_pagatore=#{session[:cf]}"
                fullquerystring = URI.unescape(queryString)
                qs = fullquerystring.sub(/&hqs=\w*/,"").strip+"3ur0s3rv1z1"
                hqs = OpenSSL::Digest::SHA1.new(qs)
  #               puts "hqs is [#{hqs}]"
                url = "#{session[:dominio]}/servizi/pagamenti/"
                if(statoPagamenti.nil? || !statoPagamenti["esito"]=="ok")
                  url = "#{session[:dominio]}/servizi/pagamenti/aggiungi_pagamento_pagopa?#{queryString}"
                end
              end
            end
            result["certificati"] << { 
              "id": richiesta_certificato.id, 
              "nome_certificato": richiesta_certificato.nome_certificato, 
              "codice_fiscale": richiesta_certificato.codice_fiscale, 
              "stato": richiesta_certificato.stato, 
              "documento": url,
              "data_prenotazione": richiesta_certificato.data_prenotazione,
              "data_inserimento": richiesta_certificato.data_inserimento,
              "esenzione": richiesta_certificato.bollo_esenzione, 
              "importo": importo
            }
          else
            result["richiesteCertificati"] << { 
              "id": richiesta_certificato.id, 
              "nome_certificato": richiesta_certificato.nome_certificato, 
              "codice_fiscale": richiesta_certificato.codice_fiscale, 
              "stato": richiesta_certificato.stato, 
              "data_prenotazione": richiesta_certificato.data_prenotazione,
              "esenzione": richiesta_certificato.bollo_esenzione, 
              "importo": importo
            }
          end
        end
      end
    end

    render :json => result
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
    
  private

  def carica_variabili_layout
    @nome = session[:user]["nome"]
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

    if Rails.env.development? 
      @demografici_data["test"] = true
    else
      @demografici_data["test"] = false
    end
  end

  def get_dominio_sessione_utente
    begin
      # reset_session
      #permetto di usare tutti i parametri e li converto in hash
      hash_params = params.permit!.to_hash
      if !hash_params['c_id'].blank? && session[:client_id] != hash_params['c_id']
        reset_session
      end
      if session.blank? || session[:user].blank? #controllo se ho fatto login
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
            session[:user] = jwt_data #uso questo oggetto per capire se utente connesso!
            puts "received hash"
            puts jwt_data
            puts "received cf is "+jwt_data[:cf]
            session[:cf] = jwt_data[:cf]
            @nome = jwt_data[:nome] 
            @cognome = jwt_data[:cognome]
            session[:client_id] = hash_params['c_id']
            # TODO gestire meglio il dominio, aspettiamo setup a db
            solo_dom = @dominio.gsub("/portal","")
            
          else
            #se ho problemi ritorno su portale con parametro di errore
            unless @dominio.blank?
              redirect_to @dominio+"/?err"
              return
            else
              redirect_to sconosciuto_url
              return   
            end
            
          end
        else

          unless @dominio.blank?
            #mando a fare autenticazione sul portal
            redirect_to @dominio+"/autenticazione"
            return
          else
            redirect_to sconosciuto_url
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
            html_layout = html_layout.gsub("</body>","<script type='text/javascript'>var demograficiData = <%=@demografici_data.to_json.html_safe%>;</script></body>")
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
