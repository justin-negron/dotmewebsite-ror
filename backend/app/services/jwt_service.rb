class JwtService
  ACCESS_TOKEN_EXPIRY = 15.minutes
  REFRESH_TOKEN_EXPIRY = 7.days

  class AuthenticationError < StandardError; end

  class << self
    def encode_access_token(admin)
      payload = {
        admin_id: admin.id,
        exp: ACCESS_TOKEN_EXPIRY.from_now.to_i,
        iat: Time.current.to_i,
        jti: SecureRandom.uuid,
        type: 'access'
      }
      JWT.encode(payload, secret, 'HS256')
    end

    def encode_refresh_token(admin)
      jti = SecureRandom.uuid
      exp = REFRESH_TOKEN_EXPIRY.from_now

      payload = {
        admin_id: admin.id,
        exp: exp.to_i,
        iat: Time.current.to_i,
        jti: jti,
        type: 'refresh'
      }

      admin.update_columns(refresh_token_jti: jti, refresh_token_exp: exp)

      JWT.encode(payload, secret, 'HS256')
    end

    def decode(token)
      decoded = JWT.decode(token, secret, true, { algorithm: 'HS256' })
      decoded.first.with_indifferent_access
    rescue JWT::ExpiredSignature
      raise AuthenticationError, 'Token has expired'
    rescue JWT::DecodeError => e
      raise AuthenticationError, "Invalid token: #{e.message}"
    end

    private

    def secret
      ENV.fetch('JWT_SECRET') do
        raise 'JWT_SECRET environment variable is not set'
      end
    end
  end
end
