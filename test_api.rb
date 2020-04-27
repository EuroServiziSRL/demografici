# -*- encoding : utf-8 -*-
require 'openssl'
require "net/http"
require "uri"
require 'httparty'
require 'byebug'

RECEIVE_TIMEOUT = 600

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
    # unless response.blank?
        return response.to_hash['access_token']
    # else
        # raise "Errore in get token"
    # end
end
puts "richiedo token a starttest"

token = get_jwt_token_authhub
puts ""

puts "richiedi_prenotazioni (ricerca per data)"
hash_params = { 'tenant' => '97d6a602-2492-4f4c-9585-d2991eb3bf4c','data' => '2020-04-02'}
response = HTTParty.post("http://localhost:3000/api/richiedi_prenotazioni/",

            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
            :follow_redirects => false,
            :timeout => 500 )

puts response
puts ""

# puts "richiedi_prenotazioni"
# hash_params = { 'tenant' => '97d6a602-2492-4f4c-9585-d2991eb3bf4c'
# }
# response = HTTParty.post("http://localhost:3000/api/richiedi_prenotazioni/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""

# puts "richiedi_prenotazioni (ricerca per stato)"
# hash_params = { 'tenant' => '97d6a602-2492-4f4c-9585-d2991eb3bf4c','stato' => 'in_attesa'}
# response = HTTParty.post("http://localhost:3000/api/richiedi_prenotazioni/",

#             :body => hash_params,
#             :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
#             :follow_redirects => false,
#             :timeout => 500 )

# puts response
# puts ""

puts "richiedi_prenotazioni (ricerca per stato e data)"
hash_params = { 'tenant' => '97d6a602-2492-4f4c-9585-d2991eb3bf4c','data' => '2020-03-30','stato' => 'in_attesa'}
response = HTTParty.post("http://localhost:3000/api/richiedi_prenotazioni/",

            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
            :follow_redirects => false,
            :timeout => 500 )

puts response
puts ""

puts "ricevi_certificato"
hash_params = { 'tenant' => '97d6a602-2492-4f4c-9585-d2991eb3bf4c',
'richiesta' => '12',
'certificato' => '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b2JqCgo0IDAgb2JqCjw8L1R5cGUvUGFnZXMKL1Jlc291cmNlcyAxMSAwIFIKL01lZGlhQm94WyAwIDAgNTk1IDg0MiBdCi9LaWRzWyAxIDAgUiBdCi9Db3VudCAxPj4KZW5kb2JqCgoxMiAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgNCAwIFIKL09wZW5BY3Rpb25bMSAwIFIgL1hZWiBudWxsIG51bGwgMF0KL0xhbmcoaXQtSVQpCj4+CmVuZG9iagoKMTMgMCBvYmoKPDwvQXV0aG9yPEZFRkYwMDY5MDA3MjAwNjUwMDZFMDA2NTAwMjA+Ci9DcmVhdG9yPEZFRkYwMDU3MDA3MjAwNjkwMDc0MDA2NTAwNzI+Ci9Qcm9kdWNlcjxGRUZGMDA0QzAwNjkwMDYyMDA3MjAwNjUwMDRGMDA2NjAwNjYwMDY5MDA2MzAwNjUwMDIwMDAzMzAwMkUwMDM1PgovQ3JlYXRpb25EYXRlKEQ6MjAxNTA2MjUxNzEwMDIrMDInMDAnKT4+CmVuZG9iagoKeHJlZgowIDE0CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwNjE2MiAwMDAwMCBuIAowMDAwMDAwMDE5IDAwMDAwIG4gCjAwMDAwMDAyNDQgMDAwMDAgbiAKMDAwMDAwNjMwNSAwMDAwMCBuIAowMDAwMDAwMjY0IDAwMDAwIG4gCjAwMDAwMDUyODggMDAwMDAgbiAKMDAwMDAwNTMwOSAwMDAwMCBuIAowMDAwMDA1NTAwIDAwMDAwIG4gCjAwMDAwMDU4NTkgMDAwMDAgbiAKMDAwMDAwNjA3NSAwMDAwMCBuIAowMDAwMDA2MTA3IDAwMDAwIG4gCjAwMDAwMDY0MDQgMDAwMDAgbiAKMDAwMDAwNjUwMSAwMDAwMCBuIAp0cmFpbGVyCjw8L1NpemUgMTQvUm9vdCAxMiAwIFIKL0luZm8gMTMgMCBSCi9JRCBbIDxEMjU5QUI1OUNGOTk1NTQwN0U1MzA2NjFGRUE2Mjg5Qz4KPEQyNTlBQjU5Q0Y5OTU1NDA3RTUzMDY2MUZFQTYyODlDPiBdCi9Eb2NDaGVja3N1bSAvMzg4QzZBNjU0NUExNTQxQTA4QUNGRTc0RDE0RENFNjMKPj4Kc3RhcnR4cmVmCjY3MTQKJSVFT0YK'
}
response = HTTParty.post("http://localhost:3000/api/ricevi_certificato/",

            :body => hash_params,
            :headers => { 'Content-Type' => 'application/x-www-form-urlencoded', 'Authorization' => 'Bearer '+token },
            :follow_redirects => false,
            :timeout => 500 )

puts response
puts ""