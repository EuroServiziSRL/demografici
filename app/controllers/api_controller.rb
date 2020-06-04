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
        "codice_esito": "003-Errore generico",
        "errore_descrizione": autenticato["msg_errore"]
      }
    else
      if params[:tenant].nil?
        esito << {
          "codice_esito": "003-Errore generico",
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
          array_codici = eval richiesta_certificato.codici_certificato
          prenotazioni << {
            "tenant": richiesta_certificato.tenant,
            "codice_fiscale": richiesta_certificato.codice_fiscale,
            "codici_certificato": array_codici, # ottenuti da compilazione form da parte del cittadino, questi verranno ottenuti da ws che restituisce elenco tipi certificato
            "bollo": richiesta_certificato.bollo, # ottenuti da compilazione form da parte del cittadino, sì/no
            "diritti_importo": richiesta_certificato.diritti_importo, # ottenuti da compilazione form da parte del cittadino, sì/no
            "uso": richiesta_certificato.uso, # ottenuti da compilazione form da parte del cittadino, probabilmente recuperati da ws?
            "richiedente_cf": richiesta_certificato.richiedente_cf,
            "richiedente_nome": richiesta_certificato.richiedente_nome,
            "richiedente_cognome": richiesta_certificato.richiedente_cognome,
            "richiedente_data_nascita": richiesta_certificato.richiedente_data_nascita,
            "richiedente_doc_riconoscimento": richiesta_certificato.richiedente_doc_riconoscimento,
            "richiedente_doc_data": richiesta_certificato.richiedente_doc_data,
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

    if autenticato["esito"]=="ko"
      array_json << {
        "codice_esito": "003-Errore generico",
        "errore_descrizione": autenticato["msg_errore"]
      }
    else
      if params[:tenant].nil?
        array_json << {
          "codice_esito": "003-Errore generico",
          "errore_descrizione": "è necessario specificare un tenant"
        }
      elsif params[:richiesta].nil?
        array_json << {
          "codice_esito": "003-Errore generico",
          "errore_descrizione": "è necessario specificare una richiesta"
        } 
      elsif params[:esito_emissione] == "001-Certificato presente" 

        searchParams[:id] = params[:richiesta]
        searchParams[:stato] = "richiesto"
        richiesta_certificato = Certificati.find_by_id(params[:richiesta])  
        if richiesta_certificato.blank? || richiesta_certificato.nil?
          array_json << {
            "codice_esito": "003-Errore generico",
            "errore_descrizione": "richiesta non trovata"
          }
        else
          richiesta_certificato.stato = "presente"
          richiesta_certificato.data_inserimento = Time.now
          richiesta_certificato.save
          array_json << {
            "codice_esito": "002-Richiesta aggiornata"
          }
        end

      elsif params[:esito_emissione] == "002-Certificato non emettibile" 

        searchParams[:id] = params[:richiesta]
        searchParams[:stato] = "richiesto"
        richiesta_certificato = Certificati.find_by_id(params[:richiesta])  
        if richiesta_certificato.blank? || richiesta_certificato.nil?
          array_json << {
            "codice_esito": "003-Errore generico",
            "errore_descrizione": "richiesta non trovata"
          }
        elsif richiesta_certificato.documento.present?
          array_json << {
            "codice_esito": "001-Certificato presente"
          }
        else
          richiesta_certificato.stato = "non_emettibile"
          richiesta_certificato.data_inserimento = Time.now
          richiesta_certificato.save
          array_json << {
            "codice_esito": "002-Richiesta aggiornata"
          }
        end


      elsif params[:esito_emissione] == "003-Errore generico" 

        searchParams[:id] = params[:richiesta]
        searchParams[:stato] = "richiesto"
        richiesta_certificato = Certificati.find_by_id(params[:richiesta])  
        if richiesta_certificato.blank? || richiesta_certificato.nil?
          array_json << {
            "codice_esito": "003-Errore generico",
            "errore_descrizione": "richiesta non trovata"
          }
        elsif richiesta_certificato.documento.present?
          array_json << {
            "codice_esito": "001-Certificato presente"
          }
        else
          richiesta_certificato.stato = "errore"
          richiesta_certificato.descrizione_errore = params[:errore_descrizione]
          richiesta_certificato.data_inserimento = Time.now
          richiesta_certificato.save
          array_json << {
            "codice_esito": "002-Richiesta aggiornata"
          }
        end

      elsif params[:certificato].nil?
        array_json << {
          "codice_esito": "003-Errore generico",
          "errore_descrizione": "il certificato non può essere vuoto"
        }
      else
        searchParams[:id] = params[:richiesta]
        searchParams[:stato] = "richiesto"
        richiesta_certificato = Certificati.find_by_id(params[:richiesta])
  
        if richiesta_certificato.blank? || richiesta_certificato.nil?
          array_json << {
            "codice_esito": "003-Errore generico",
            "errore_descrizione": "richiesta non trovata"
          }
        elsif richiesta_certificato.documento.present?
          array_json << {
            "codice_esito": "001-Certificato presente"
          }
        else
          basedir = createPath( [params[:tenant], Time.now.year.to_s, Time.now.month.to_s] )
          puts basedir

          # creo file 
          prefix = richiesta_certificato.codici_certificato
          prefix = prefix.gsub('[','').gsub(']','').gsub(' ','').gsub(',','.')

          importo = 0
          if !richiesta_certificato.bollo.nil?
            importo = importo+richiesta_certificato.bollo
          end
          if !richiesta_certificato.diritti_importo.nil?
            importo = importo+richiesta_certificato.diritti_importo
          end

          path = File.join(basedir, prefix+"_"+richiesta_certificato.codice_fiscale+".pdf")
          File.open(path, "wb") { |f| f.write(Base64.decode64(params[:certificato])) }
          richiesta_certificato.documento = path
          richiesta_certificato.stato = ( importo>0 ? "da_pagare" : "pagato" )
          richiesta_certificato.data_inserimento = Time.now
          richiesta_certificato.save
          # TODO inviare mail a utente
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
    nomi_certificati = ['Anagrafico di nascita', 'Anagrafico di morte', 'Anagrafico di matrimonio', 'Cancellazione anagrafica', 'Cittadinanza', 'Esistenza in vita', 'Residenza', 'Residenza AIRE', 'Stato civile', 'Stato di famiglia', 'Stato di famiglia e di stato civile', 'Residenza in convivenza', 'Stato di famiglia AIRE', 'Stato di famiglia con rapporti di parentela', 'di Stato Libero', 'Anagrafico di Unione Civile', 'di Contratto di Convivenza'] 

    cf = ['CRZGBR90A01C573P', 'DPLDRD89A09L219Y', 'PPPFNC20E01C573N', 'RYSRLN45A20L651X', 'STHFLV81L70Z602Z', 'STHMTR97A65Z602C', 'STHRSR76B68Z602F', 'TSTTTD20E01Z110T', 'TLTLND08H08Z602H', 'TLTTBS13M12Z602S', 'VLNDYD63H16Z133B', 'VLNGFF91E48Z133Y', 'VLNLVN51C48C573Q', 'VNCNYN60E57Z133D', 'VNCDNN71E02Z602L', 'VNCNCN95M09Z133D', 'VNCVTI68R56F187W', 'VNCMGM68E55Z133W', 'VNCVST61L22Z133M', 'VNCPCR97R68Z133F', 'VNCSTL49D56F853W', 'ZNNMNN96T24Z123F', 'ZNNRRG91E12Z123C', 'ZNNBBC80S47Z112M', 'ZNNGZM77T48Z602V', 'ZNNKJS31C50C573X', 'ZNNLVN54H62Z103L', 'ZNNMTS02S27C794P', 'ZNNSRR95L27Z123A', 'ZNNSDR54B19C573K', 'ZNNSDR56L13Z133I', 'ZNNTRS67C41F187G', 'ZNNVNN55L71Z114S', 'ZNNVLG63M42Z133L', 'ZRCNIO25R67C573F', 'ZRCNIO82A50L378H', 'ZRCMLL64D42Z602W', 'ZRCMFR85E13Z602R', 'ZRCNLT35S61C573K', 'ZRCTTV66M26Z112E', 'ZRCRNT73M49Z602B', 'ZRCSDR37E66C573E', 'ZCEMRS35C43C573Z', 'ZNECRN95C65Z401W', 'ZNECRS49E24Z602A', 'ZNEDLC74B67F187Y', 'ZNERHR01E02Z401Q', 'ZNEWHR35T42C002O', 'ZMMNNZ85H55Z600D', 'ZMMDNM69C43Z133H', 'ZMMDLE61M46Z103T', 'ZMMLNE96R05Z602Z', 'ZMMLTN99C22Z602W', 'ZMMRLD35R22C573D', 'ZMMRSR68L66Z133A', 'ZMMRHG87L05Z600V', 'ZTTMLA69A21Z103B', 'ZTTNLS45E31C573Q', 'ZTTNLM64P30Z133Q', 'ZTTRNN62D57F187A', 'ZTTZZA52P41C573Z', 'ZTTCML44T26C573E', 'ZTTCML75D20Z700G', 'ZTTCDS41R04Z602Z', 'ZTTCCT58P46Z112A', 'ZTTCST76L12Z602L', 'ZTTDFN76L52Z602L', 'ZTTDLN47D28C573T', 'ZTTLDL60S41Z602F', 'ZTTLNE86S30Z602V', 'ZTTRKE70T61Z133V', 'ZTTRLN40R47Z602R', 'ZTTNCE73E53Z602I', 'ZTTFLP69R46Z602U', 'ZTTFLP90H22Z103B', 'ZTTGRL43R01Z602Q', 'ZTTGRG23D22C573X', 'ZTTGMN54H14C573K', 'ZTTGSN01M23L378E', 'ZTTGRN91S12Z103Z', 'ZTTLDI42R60Z401M', 'ZTTNIO85H03Z103A', 'ZTTSLD70B55Z602F', 'ZTTVNI31E04Z602U', 'ZTTJNT51E45Z602H', 'ZTTKTA57T50Z103W', 'ZTTLNE78A43F712A', 'ZTTLRD77P08Z602N', 'ZTTLVN77C51Z602N', 'ZTTLCU49D64Z602V', 'ZTTLVC66A68Z133F', 'ZTTLGN60B04C573S', 'ZTTLFR85D28Z600I', 'ZTTLDL54C67Z600P', 'ZTTMTR80R67Z600I', 'ZTTMFL46P45Z602Q', 'ZTTMSV75M69Z600B', 'ZTTMDN74A53Z103Y', 'ZTTMHL91C67Z103W', 'ZTTMRC80H14Z602N', 'ZTTMST67E27Z602M', 'ZTTMHD52E11Z103P', 'ZTTPRD58T28Z602B', 'ZTTPNT73S13Z600J', 'ZTTTLZ60L60Z602T', 'ZTTTLR54D14C573D', 'ZTTTLL50B10C573E', 'ZTTWDM34E07Z602X', 'ZTTWHL31L08C573K', 'ZTTYNN42L59Z602R', 'ZCLDNV92P01Z401D', 'ZCLLCD60M16Z404K', 'ZCLNYN61R01Z401H', 'ZCLCRL71T67Z133K', 'ZCLGPR20C11C573R', 'ZCLLNR55E42Z600Y', 'ZCLLVI92A70Z401U', 'ZCLLNN89C64Z401Z', 'ZCLLCC42T49C573W', 'ZCLNLS60S19Z133S', 'ZCLLVO14M07Z110A', 'ZCLSCR79M20L378E', 'ZCLPCR02D05Z103R', 'ZCLRCD75M13Z133H', 'ZCLRTM94T65Z401I', 'ZCLSVA11S26Z110K', 'ZCLWHR94L49Z401R', 'ZCHBHR00D47Z133L', 'ZCHBNG75E09Z602K', 'ZCHDNN44S10Z602U', 'ZCHZEI34L09C573T', 'ZCHJSJ77A19Z602I', 'ZCHLRB68D27Z133Q', 'ZCHLSU98C57Z133U', 'ZCHMCS52C30Z602Q', 'ZCHMGR63C58Z602W', 'ZCHPZW70H07Z602Q', 'ZCHRDF04D29Z602V', 'ZCHRSR66C57Z602Z', 'ZCHSST72L24Z602O', 'ZCHVDN74E03Z602J', 'ZCHVTI56C31C002Q', 'ZCHWMR72E25Z602F', 'BNCNDR91A01F206Z', 'TSTTTB55A01C573Y', 'TSTTTT55A01C573Q', 'ZTTGTN39E31Z602G', 'RYSNMR85C71Z514U', 'RYSDCO83P59Z514J', 'VLNDRC59S55Z330M', 'VLNSTL03C46Z602B', 'ZNNGTN72P09Z127U', 'ZNNMRA50T58Z129T', 'ZNNNNJ01B14A944O', 'ZNNRLA72S64Z160Z', 'ZNNBTS45B23D468T', 'ZNNBMN05T08L378P', 'ZNNCLL82T45Z129R', 'ZNNCTR63S53Z129X', 'ZNNDNE60A01Z160B', 'ZNNLBT03S67Z129R', 'ZNNDIA74C53Z127E', 'ZNNNIO52E63Z129F', 'ZNNLNE06E41Z129D', 'ZNNLFR74B04Z127P', 'ZNNMGR04R42L378K', 'ZNNMRA83S04Z330Z', 'ZNNMGN78R25Z129K', 'ZNNSNT69P48Z129D', 'ZNNSVN96M28Z160N', 'ZNNVGN75E41Z127C', 'ZRCLSS63S58A944S', 'ZRCGLI71P64Z138Q', 'ZRCSCL09R57L378H', 'ZCEBBR66S56Z129X', 'ZCEMRN69H09Z118S', 'ZCESFA00M53Z138N', 'ZCESRA77D55Z138A', 'ZNELMR51D58Z114P', 'ZMMXVH83T07Z330A', 'ZTTDLN70L66Z129K', 'ZTTLSN66R05Z129A', 'ZTTNXY90L19Z129F', 'ZCLSRD70E68A944N', 'ZCLRLA63B15Z160K', 'ZCLLRA01P53Z160T', 'ZCLLLN69S68Z160U', 'ZCLPLM07R61C794P', 'ZCLPCD00B52Z160R', 'ZCLVGN80E29Z138U', 'ZCHDTS09S14C794Q', 'ZCHNZE80C31A944N', 'ZCHDLM75R61Z129P', 'ZCHJDY81T10Z129K', 'ZCHLLR87M64A944L', 'ZCHMLK36L61Z110O', 'ZCHPTR05A47C794X', 'ZCHTSN88L42A944E' ]

    cognomi = ['CROZZA', 'DI PALMA', 'PIPPO', 'REYES DE SOUZA', 'SAUTHIER SEIXAS', 'SAUTHIER SEIXAS', 'SAUTHIER SEIXAS', 'TESTCC', 'TOLOTTI BERTI', 'TOLOTTI BERTI', 'VALENTINELLI', 'VALENTINELLI', 'VALENTINELLI', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'VINCIGUERRA', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZEC', 'ZENI', 'ZENI', 'ZENI', 'ZENI', 'ZENI', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZIMMERMANN', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'BIANCHI', 'TEST', 'TESTSTU', 'ZOTTELE', 'REYES DE SOUZA', 'REYES DE SOUZA', 'VALENTINELLI', 'VALENTINELLI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZANONI', 'ZARUCCHI', 'ZARUCCHI', 'ZARUCCHI', 'ZEC', 'ZEC', 'ZEC', 'ZEC', 'ZENI', 'ZIMMERMANN', 'ZOTTELE', 'ZOTTELE', 'ZOTTELE', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUCOLOTTO', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH', 'ZUECH' ]

    nomi = ['GILBERTO', 'EDOARDO', 'FRANCO', 'RUSLAN', 'FULVIA', 'MARIA TERESA', 'ROSARIA', 'TESTDFR', 'LAURINDO LUIZ', 'TOBIAS', 'DAVYD', 'GIOSEFFA', 'LIVIANA', 'ANIOXY ANDREA', 'EDSON ANTONIO', 'INNOCENTE', 'IVETE', 'MARIA GEMMA', 'OVIDIU STEFAN', 'PAOLA CARLA', 'STELA', 'AMINEANNIOXY', 'ARRIGO', 'BABIC', 'GRAZIA MARIA', 'KATJA SONJA', 'LIVIANA', 'MATIAS', 'OSCAR RAIMUNDO', 'SANDRO', 'SANDRO', 'THERESINHA', 'VANNA', 'VILLA GOTTER GAIA', 'IOANA', 'IOANA', 'MAITELLI HILDA', 'MARIO FORTUNATO', 'NICOLETTA', 'OTTAVIO', 'RENATA', 'SANDRINA', 'MARIA ROSA', 'CATERINA', 'CHRISTOPHER', 'DORALICE', 'RICHARD PATRICK', 'WEGHER SILVANA', 'ANNUNZIATA', 'DAMIANA MARIA', 'DELIA', 'ELIANE', 'ELIO TINO', 'RINALDO', 'ROSARIA', 'RUTH AGNES', 'AMELIO', 'ANGELIS FRANCESCO', 'ANSELMO', 'ARIANNA', 'AZIZ', 'CARMELO', 'CARMELO', 'CLAUDIO SERGIO', 'CONCETTA', 'CRISTIANO', 'DELFINA', 'DYLAN', 'ELENA ADELAIDE', 'ELIANE', 'ERIKA', 'ERMELINDA VIRGINIA', 'EUNICE', 'FELIPE', 'FELIPE', 'GABRIEL FILIPE', 'GEORGE', 'GERMANO', 'GERSONA', 'GUERRINO', 'ILDE', 'ION', 'ISOLDA', 'IVAN', 'JANETE', 'KATIA', 'LEONA', 'LEONARDO', 'LIVIANA', 'LUCIA', 'LUDOVICA', 'LUIGINO', 'LUIS FERNANDO', 'LUIZA DALZOCHIO', 'MARA TEREZINHA', 'MARIA FLORENCIA', 'MARISA VIRGINIA', 'MASI DANIELA', 'MICHELA', 'MIRCEA', 'MODESTO', 'MOUJAHIDI SALAH', 'PARIDE', 'PAULO ANTONIO', 'TAYLA ZOE', 'TAYLOR EMILIO', 'TULLIO', 'WALDEMIRO CLAUDINO', 'WILHELM', 'YVONNE MARISA', 'ADRIAN OVIDIU', 'ALCIDE', 'ANIOXY ANDREA', 'CARLA', 'GIAMPIERO', 'LILIANA ROSA', 'LIVIA', 'LUCIA ANNA', 'LUCICA', 'NELU ALESSIO', 'OLIVO', 'OSCAR', 'POLICARPO', 'ROCCO DOMENICO', 'ROSITA MARIA', 'SAVU', 'WEGHER SUSANNA', 'BAHRIE', 'BRUNO GIUSEPPE', 'EDSON ANTONIO', 'EZIO', 'JAMES JULIAN', 'LARBI', 'LUISA', 'MARCOS ANTONIO', 'MARIA GRAZIA', 'PEREZ WILLIAM JOSE\'', 'RONDA FLOTENTINO', 'ROSARIA', 'SEBASTIANO', 'VALDUINO GERMANO', 'VITO', 'WILMAR ALFONSO', 'ANDREA', 'TESTAB', 'TESTTTT', 'AGOSTINO ALBINO', 'ANA MARIA', 'DOCA', 'DIRCE', 'STELA', 'AGOSTINO', 'AMIRA', 'ANTONIO JOSE\'', 'AURELIA', 'BATTISTA', 'BENIAMINO', 'CAMILLA', 'CATTERINA', 'EDUINO', 'ELZBIETA', 'IDA', 'IOANA', 'LEONA', 'LUIZ FORMOLO', 'MARIAGRAZIA', 'MARIO', 'MARIO IGINIO', 'SAMANTA', 'SILVINO', 'VERGANI FORMOLO', 'ALESSIA', 'GIULIA', 'SCEILA', 'BARBARA FRANZISKA', 'MARIN', 'SAFIA', 'SARA', 'LISA MARIA', 'XHEVAHIR', 'ADELINA', 'ALYSON', 'EANNIOXY ANDREA', 'ASTRID', 'AURELIO', 'LARA', 'LILIANE', 'PALMA', 'PLACIDA', 'VIRGINIO', 'DANTAS IBERE', 'ENZO', 'IDELMA', 'JODY', 'LUCILA RADDATZ', 'MALIKA', 'PETRA', 'TERESINA']

    date_nascita = ['1990-01-01T00:00:00.000', '1989-01-09T00:00:00.000', '2020-05-01T00:00:00.000', '1945-01-20T00:00:00.000', '1981-07-30T00:00:00.000', '1997-01-25T00:00:00.000', '1976-02-28T00:00:00.000', '2020-05-01T00:00:00.000', '2008-06-08T00:00:00.000', '2013-08-12T00:00:00.000', '1963-06-16T00:00:00.000', '1991-05-08T00:00:00.000', '1951-03-08T00:00:00.000', '1960-05-17T00:00:00.000', '1971-05-02T00:00:00.000', '1995-08-09T00:00:00.000', '1968-10-16T00:00:00.000', '1968-05-15T00:00:00.000', '1961-07-22T00:00:00.000', '1997-10-28T00:00:00.000', '1949-04-16T00:00:00.000', '1996-12-24T00:00:00.000', '1991-05-12T00:00:00.000', '1980-11-07T00:00:00.000', '1977-12-08T00:00:00.000', '1931-03-10T00:00:00.000', '1954-06-22T00:00:00.000', '2002-11-27T00:00:00.000', '1995-07-27T00:00:00.000', '1954-02-19T00:00:00.000', '1956-07-13T00:00:00.000', '1967-03-01T00:00:00.000', '1955-07-31T00:00:00.000', '1963-08-02T00:00:00.000', '1925-10-27T00:00:00.000', '1982-01-10T00:00:00.000', '1964-04-02T00:00:00.000', '1985-05-13T00:00:00.000', '1935-11-21T00:00:00.000', '1966-08-26T00:00:00.000', '1973-08-09T00:00:00.000', '1937-05-26T00:00:00.000', '1935-03-03T00:00:00.000', '1995-03-25T00:00:00.000', '1949-05-24T00:00:00.000', '1974-02-27T00:00:00.000', '2001-05-02T00:00:00.000', '1935-12-02T00:00:00.000', '1985-06-15T00:00:00.000', '1969-03-03T00:00:00.000', '1961-08-06T00:00:00.000', '1996-10-05T00:00:00.000', '1999-03-22T00:00:00.000', '1935-10-22T00:00:00.000', '1968-07-26T00:00:00.000', '1987-07-05T00:00:00.000', '1969-01-21T00:00:00.000', '1945-05-31T00:00:00.000', '1964-09-30T00:00:00.000', '1962-04-17T00:00:00.000', '1952-09-01T00:00:00.000', '1944-12-26T00:00:00.000', '1975-04-20T00:00:00.000', '1941-10-04T00:00:00.000', '1958-09-06T00:00:00.000', '1976-07-12T00:00:00.000', '1976-07-12T00:00:00.000', '1947-04-28T00:00:00.000', '1960-11-01T00:00:00.000', '1986-11-30T00:00:00.000', '1970-12-21T00:00:00.000', '1940-10-07T00:00:00.000', '1973-05-13T00:00:00.000', '1969-10-06T00:00:00.000', '1990-06-22T00:00:00.000', '1943-10-01T00:00:00.000', '1923-04-22T00:00:00.000', '1954-06-14T00:00:00.000', '2001-08-23T00:00:00.000', '1991-11-12T00:00:00.000', '1942-10-20T00:00:00.000', '1985-06-03T00:00:00.000', '1970-02-15T00:00:00.000', '1931-05-04T00:00:00.000', '1951-05-05T00:00:00.000', '1957-12-10T00:00:00.000', '1978-01-03T00:00:00.000', '1977-09-08T00:00:00.000', '1977-03-11T00:00:00.000', '1949-04-24T00:00:00.000', '1966-01-28T00:00:00.000', '1960-02-04T00:00:00.000', '1985-04-28T00:00:00.000', '1954-03-27T00:00:00.000', '1980-10-27T00:00:00.000', '1946-09-05T00:00:00.000', '1975-08-29T00:00:00.000', '1974-01-13T00:00:00.000', '1991-03-27T00:00:00.000', '1980-06-14T00:00:00.000', '1967-05-27T00:00:00.000', '1952-05-11T00:00:00.000', '1958-12-28T00:00:00.000', '1973-11-13T00:00:00.000', '1960-07-20T00:00:00.000', '1954-04-14T00:00:00.000', '1950-02-10T00:00:00.000', '1934-05-07T00:00:00.000', '1931-07-08T00:00:00.000', '1942-07-19T00:00:00.000', '1992-09-01T00:00:00.000', '1960-08-16T00:00:00.000', '1961-10-01T00:00:00.000', '1971-12-27T00:00:00.000', '2020-03-11T00:00:00.000', '1955-05-02T00:00:00.000', '1992-01-30T00:00:00.000', '1989-03-24T00:00:00.000', '1942-12-09T00:00:00.000', '1960-11-19T00:00:00.000', '2014-08-07T00:00:00.000', '1979-08-20T00:00:00.000', '2002-04-05T00:00:00.000', '1975-08-13T00:00:00.000', '1994-12-25T00:00:00.000', '2011-11-26T00:00:00.000', '1994-07-09T00:00:00.000', '2000-04-07T00:00:00.000', '1975-05-09T00:00:00.000', '1944-11-10T00:00:00.000', '1934-07-09T00:00:00.000', '1977-01-19T00:00:00.000', '1968-04-27T00:00:00.000', '1998-03-17T00:00:00.000', '1952-03-30T00:00:00.000', '1963-03-18T00:00:00.000', '1970-06-07T00:00:00.000', '2004-04-29T00:00:00.000', '1966-03-17T00:00:00.000', '1972-07-24T00:00:00.000', '1974-05-03T00:00:00.000', '1956-03-31T00:00:00.000', '1972-05-25T00:00:00.000', '1991-01-01T00:00:00.000', '1955-01-01T00:00:00.000', '1955-01-01T00:00:00.000', '1939-05-31T00:00:00.000','1985-03-31T00:00:00.000', '1983-09-19T00:00:00.000', '1959-11-15T00:00:00.000', '2003-03-06T00:00:00.000', '1972-09-09T00:00:00.000', '1950-12-18T00:00:00.000', '2001-02-14T00:00:00.000', '1972-11-24T00:00:00.000', '1945-02-23T00:00:00.000', '2005-12-08T00:00:00.000', '1982-12-05T00:00:00.000', '1963-11-13T00:00:00.000', '1960-01-01T00:00:00.000', '2003-11-27T00:00:00.000', '1974-03-13T00:00:00.000', '1952-05-23T00:00:00.000', '2006-05-01T00:00:00.000', '1974-02-04T00:00:00.000', '2004-10-02T00:00:00.000', '1983-11-04T00:00:00.000', '1978-10-25T00:00:00.000', '1969-09-08T00:00:00.000', '1996-08-28T00:00:00.000', '1975-05-01T00:00:00.000', '1963-11-18T00:00:00.000', '1971-09-24T00:00:00.000', '2009-10-17T00:00:00.000', '1966-11-16T00:00:00.000', '1969-06-09T00:00:00.000', '2000-08-13T00:00:00.000', '1977-04-15T00:00:00.000', '1951-04-18T00:00:00.000', '1983-12-07T00:00:00.000', '1970-07-26T00:00:00.000', '1966-10-05T00:00:00.000', '1990-07-19T00:00:00.000', '1970-05-28T00:00:00.000', '1963-02-15T00:00:00.000', '2001-09-13T00:00:00.000', '1969-11-28T00:00:00.000', '2007-10-21T00:00:00.000', '2000-02-12T00:00:00.000', '1980-05-29T00:00:00.000', '2009-11-14T00:00:00.000', '1980-03-31T00:00:00.000', '1975-10-21T00:00:00.000', '1981-12-10T00:00:00.000', '1987-08-24T00:00:00.000', '1936-07-21T00:00:00.000', '2005-01-07T00:00:00.000', '1988-07-02T00:00:00.000']

    docs = ['patente','carta d\'identità','passaporto']

    max = cf.length

    while x < 20      
      certificato_random = rand(nomi_certificati.length)
      richiedente_random = rand(max)
      cf_random = rand(max)
      doc_random = rand(3)
      richiedente_diverso = rand_bool && richiedente_random != x
      cf_certificato = cf[cf_random]
      certificati_random = []
      # certificati_random.push(rand(nomi_certificati.length))
      y = 0
      while y < rand_in_range(0,5)
        certificati_random.push(rand(nomi_certificati.length)+1)
        y = y+ 1
      end
      bollo = ( rand_bool ? 0 : 16 )
      bollo_esenzione = nil
      if bollo == 0 
        bollo_esenzione = rand_in_range(1,10).round()
      end
      certificato = {
        tenant: "97d6a602-2492-4f4c-9585-d2991eb3bf4c",
        codice_fiscale: cf_certificato,
        codici_certificato: certificati_random, 
        bollo: bollo,
        bollo_esenzione: bollo_esenzione,
        diritti_importo: ( rand_bool ? 0 : rand(1.1...16.9).round(1) ),
        # diritti_importo: 0,  # per ora 0 perchè dovrebbe fornircelo l'api
        uso: "",
        richiedente_cf: ( richiedente_diverso ? cf_certificato : cf[richiedente_random] ),
        richiedente_nome: ( richiedente_diverso ? nil : nomi[richiedente_random] ),
        richiedente_cognome: ( richiedente_diverso ? nil : cognomi[richiedente_random] ),
        richiedente_doc_riconoscimento: ( richiedente_diverso ? nil : docs[doc_random] ),
        richiedente_doc_data: ( richiedente_diverso ? nil : rand_time(5.years.ago, 30.days.ago) ),
        richiedente_data_nascita: ( richiedente_diverso ? nil : date_nascita[richiedente_random] ),
        # richiesta: "",
        stato: "nuovo",
        # data_inserimento: "",
        data_prenotazione: rand_time(30.days.ago),
        # email: "",
        id_utente: rand(1000),
        # documento: "",
      }

      Certificati.create(certificato)
      array_json << certificato
   
      x = x + 1
    end    
    response = array_json.to_json  
    render :json => response
  end

  # def inserisci_prenotazione

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
  def random_cf(initial)
    o = [('A'..'Z')].map(&:to_a).flatten
    if initial.nil? || initial == ""
      initial = (0...6).map { o[rand(o.length)] }.join
    end
    string = initial + rand(99).to_s + o[rand(o.length)] + rand(71).to_s + o[rand(o.length)] + rand(999).to_s + o[rand(o.length)]
    return string
  end

  def autentica_ente
    puts "autentica_ente"
    if Rails.env.development?
      return { 'esito' => 'ok' }
    elsif !request.headers['HTTP_AUTHORIZATION'].blank? #authorization con token jwt
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