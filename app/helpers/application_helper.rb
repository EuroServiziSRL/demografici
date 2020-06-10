require 'httparty'
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
  
  
end
