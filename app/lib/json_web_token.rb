class JsonWebToken
    class << self
        def encode(payload, secret=nil, alg=nil)
            JWT.encode(payload, '6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168','HS256')
        end
   
        def decode(token) 
            body = JWT.decode(token, '6rg1e8r6t1bv8rt1r7y7b86d8fsw8fe6bg1t61v8vsdfs8erer6c18168','HS256')[0] 
            HashWithIndifferentAccess.new body 
        rescue 
            nil 
        end
        
        
        
        
        # Validates the payload hash for expiration and meta claims
        def valid_payload(payload)
            if expired(payload) || payload['iss'] != meta[:iss] || payload['aud'] != meta[:aud]
              return false
            else
              return true
            end
        end
  
    end
end