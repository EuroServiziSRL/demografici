class JsonWebToken
    class << self
        def encode(payload, secret=nil, alg=nil)
            JWT.encode(payload, Rails.application.credentials.external_auth_api_key,'HS256')
        end
   
        def decode(token) 
            body = JWT.decode(token, Rails.application.credentials.external_auth_api_key,'HS256')[0] 
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