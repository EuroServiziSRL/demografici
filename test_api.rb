# -*- encoding : utf-8 -*-
require 'openssl'
require "net/http"
require "uri"
require 'httparty'
require 'byebug'

RECEIVE_TIMEOUT = 600
# domain = "http://localhost:3000"
domain = "https://demografici.soluzionipa.it"

begin
    require 'jwt'
rescue LoadError => exc
    raise "Installare gemma jwt e usare ruby > 2"
end

def get_jwt_token_authhub

    hash_params = { 'username' => 'civilia_test@jwt.it',
                    'password' => 'PswCivilia1',
                    'grant_type'=> 'password'
                  }
    response = HTTParty.post("https://starttest.soluzionipa.it/auth_hub/oauth/token",
    # response = HTTParty.post("https://start.soluzionipa.it/auth_hub/oauth/token",

            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
            :follow_redirects => false,
            :timeout => 500 )
    unless response.empty?
        return response.to_hash['access_token']
    else
        raise "Errore in get token"
    end
end
puts "richiedo token a starttest"

token = get_jwt_token_authhub
puts token
puts ""

# puts "richiedi_prenotazioni (ricerca per data)"
# hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26','data' => '2020-04-14'}
# response = HTTParty.post(domain+"/api/richiedi_prenotazioni/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""

puts "richiedi_prenotazioni"
hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26'
}
response = HTTParty.post(domain+"/api/richiedi_prenotazioni/",

            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
            :follow_redirects => false,
            :timeout => 500 )

puts response
puts ""

# puts "richiedi_prenotazioni (ricerca per stato)"
# hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26','stato' => 'in_attesa'}
# response = HTTParty.post(domain+"/api/richiedi_prenotazioni/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""

# puts "richiedi_prenotazioni (ricerca per stato e data)"
# hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26','data' => '2020-03-30','stato' => 'in_attesa'}
# response = HTTParty.post(domain+"/api/richiedi_prenotazioni/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""

richiesta = false
if richiesta
    puts "ricevi_certificato"
    hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26',
    'richiesta' => richiesta,
    'esito_emissione' => '001-Certificato presente',
    }
    response = HTTParty.post(domain+"/api/ricevi_certificato/",

                :body => hash_params,
                :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
                :follow_redirects => false,
                :timeout => 500 )

    puts response
    puts ""
end

richiesta = false
if richiesta
    puts "ricevi_certificato"
    hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26',
    'richiesta' => richiesta,
    'esito_emissione' => '001-Certificato presente',
    'certificato' => File.read("certificato_vero")
    }
    response = HTTParty.post(domain+"/api/ricevi_certificato/",

                :body => hash_params,
                :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
                :follow_redirects => false,
                :timeout => 500, 
                :debug_output => $stdout )

    puts response
    puts ""
end


# puts "ricevi_certificato (non emettibile)"
# hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26',
# 'richiesta' => '283',
# 'esito_emissione' => '002-Certificato non emettibile',
# 'errore_descrizione' => 'Importo diritti segreteria deve essere maggiore di 0,00 euro',
# }
# response = HTTParty.post(domain+"/api/ricevi_certificato/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""


# puts "ricevi_certificato (errore generico)"
# hash_params = { 'tenant' => 'ba4785a1-abe2-4fcc-ac26-6cda29910c26',
# 'richiesta' => '22',
# 'codice_esito' => '003-Errore generico',
# 'errore_descrizione' => 'questo è un test di descrizione errore',
# }
# response = HTTParty.post(domain+"/api/ricevi_certificato/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""