require 'httparty'
require "base64"
require 'zip'
module ApplicationHelper
  
  def stato_pagamento2(urlPagamenti,idAvviso)
    headers = { 'client_id' => 'uin892IO!', 
      'req_time' => Time.now.strftime("%d%m%Y%H%M%S"), 
      'applicazione' => 'istanze', 
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    
    headers['check'] = Digest::SHA1.hexdigest("sKd80O12nmclient_id=#{headers["client_id"]}&req_time=#{headers["req_time"]}&applicazione=#{headers["applicazione"]}")
    
    result = HTTParty.post(urlPagamenti, 
    :body => "[{'id_univoco_dovuto': '#{idAvviso}'}]",
    :headers => headers ) 
    return result
  end
  
    
  def stato_pagamento(urlPagamenti,idAvviso)
    uri = URI(urlPagamenti)
	  http = Net::HTTP.new(uri.host, uri.port)
    
    client_id = "uin892IO!"
    req_time = Time.now.strftime("%d%m%Y%H%M%S")
    applicazione = "demografici"
    chiave = "sKd80O12nm"

    requestParams = { 
      'tipo_dovuto' => "certificazione_td",
      'id_univoco_dovuto' => idAvviso,
      'client_id' => client_id,
      'req_time' => req_time,
      'applicazione' => applicazione
      # 'IUV' => idAvviso
    }
                  
    params_string = ["tipo_dovuto", "id_univoco_dovuto", "client_id", "req_time", "applicazione"].map{ |chiave|
        val = requestParams[chiave] 
        "#{chiave}=#{val}"
    }.join('&')

    query_string="client_id=#{client_id}&req_time=#{req_time}&applicazione=#{applicazione}"
    #creo hash
    sha_hash = OpenSSL::Digest::SHA1.new(chiave+query_string)
    requestParams[:check] = sha_hash
    # puts "chiave+query_string: #{chiave+query_string}"
    # puts "sha_hash: #{sha_hash}"
    # puts "uri.request_uri: #{urlPagamenti}"
    request = Net::HTTP::Post.new(urlPagamenti)
    # puts "params_string: #{params_string}"
    request.set_form_data(requestParams)
    response = http.request(request)
    # puts "response: #{response.body}"
    
    return JSON.parse(response.body)
  end
  
  def verifica_pagamento(urlPagamenti,idAvviso, tipoDovuto)
    uri = URI(urlPagamenti)
    http = Net::HTTP.new(uri.host, uri.port)
    

    requestParams = { 
      'applicazione' => "pagamenti",
      'tipo_dovuto' => tipoDovuto,
      'iuv' => idAvviso,
      'mbd' => 1
    }

    response = HTTParty.post(urlPagamenti,
    :body => requestParams,
    :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+get_jwt_token_authhub },
    # :debug_output => $stdout ,
    :follow_redirects => false, # se è a false va in errore su 302 found - document has moved (caso redirect da http a https), mettere a true solo per test civilianext
    :timeout => 500 )
                     
    return JSON.parse(response.body)
  end

  def invia_multidovuto(urlPagamenti, arrayDati) 

    puts "invia_multidovuto"
    uri = URI(urlPagamenti)
    http = Net::HTTP.new(uri.host, uri.port)
    
    stringio = Zip::OutputStream::write_buffer do |zio|
      zio.put_next_entry("array_json")
          zio.write arrayDati.to_json
      end
    stringio.rewind
    c_enc64 = Base64.strict_encode64(stringio.sysread)	
    
    # compressed_data = Zlib::Deflate.deflate(arrayDati.to_json)
    # encoded_data = Base64.encode64(compressed_data)
    
    requestParams = { 
      'applicazione' => "pagamenti",
      'numero' => 1, # valorizzato con il numero di pagamenti caricati e contenuti nell'array. E’ di fatto il numero degli IUV che verranno  generati/gestiti.
      'nome_flusso' => 0, # Valorizzare a “0” per chiamate con flusso a singolo pagamento (APP)
      'caricament_da_confermare' => "false",
      'content_json' => c_enc64 # Elenco dovuti compresso in formato ZIP e da caricare in base 64
    }

    response = HTTParty.post(urlPagamenti,
    :body => requestParams,
    :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+get_jwt_token_authhub },
    # :debug_output => $stdout ,
    :follow_redirects => false,
    :timeout => 500 )
                     
    return JSON.parse(response.body)

  end

  #TODO implementare avvia_pagamento oltre a vai al carrello

  def get_jwt_token_authhub

    hash_params = { 'username' => 'civilia_test@jwt.it',
                    'password' => 'PswCivilia1',
                    'grant_type'=> 'password'
                  }
    response = HTTParty.post("https://start.soluzionipa.it/auth_hub/oauth/token",
            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
            :follow_redirects => false,
            :timeout => 500 )
    unless response.empty?
      puts "access token: #{response.to_hash['access_token']}"
      return response.to_hash['access_token']
    else
      raise "Errore in get token"
    end
  end
  
  
end
