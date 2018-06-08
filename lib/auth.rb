# frozen_string_literal: true

require "openssl"
require "base64"

# Generates jwks
class Auth
  KEY = OpenSSL::PKey::RSA.generate(1024).freeze

  def to_jwks
    { "keys": [jwk] }
  end

  private

  def jwk
    {
      "kty": "RSA",
      "use": "sig",
      "kid": "kid",
      "alg": "RS256",
      "e": e,
      "n": n
    }
  end

  def e
    encode public_key.e.to_s(2)
  end

  def n
    encode public_key.n.to_s(2)
  end

  def public_key
    KEY.public_key
  end

  def encode(string)
    Base64.urlsafe_encode64 string, padding: false
  end
end
