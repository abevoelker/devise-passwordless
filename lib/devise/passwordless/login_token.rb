module Devise::Passwordless
  class LoginToken
    class InvalidOrExpiredTokenError < StandardError; end

    def self.encode(resource, extra=nil)
      now = Time.current
      len = ActiveSupport::MessageEncryptor.key_len
      salt = SecureRandom.random_bytes(len)
      key = ActiveSupport::KeyGenerator.new(self.secret_key).generate_key(salt, len)
      crypt = ActiveSupport::MessageEncryptor.new(key, serializer: JSON)
      data = {
        data: {
          resource: {
            key: resource.to_key,
            email: resource.email,
          },
        },
        created_at: now.to_f,
      }
      data[:data][:extra] = extra if extra
      encrypted_data = crypt.encrypt_and_sign(data)
      salt_base64 = Base64.strict_encode64(salt)
      "#{salt_base64}:#{encrypted_data}"
    end

    def self.decode(token, as_of=Time.current, expire_duration=Devise.passwordless_login_within)
      raise InvalidOrExpiredTokenError if token.blank?
      salt_base64, encrypted_data = token.split(":")
      raise InvalidOrExpiredTokenError if salt_base64.blank? || encrypted_data.blank?
      begin
        salt = Base64.strict_decode64(salt_base64)
      rescue ArgumentError
        raise InvalidOrExpiredTokenError
      end
      len = ActiveSupport::MessageEncryptor.key_len
      key = ActiveSupport::KeyGenerator.new(self.secret_key).generate_key(salt, len)
      crypt = ActiveSupport::MessageEncryptor.new(key, serializer: JSON)
      begin
        decrypted_data = crypt.decrypt_and_verify(encrypted_data)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
        raise InvalidOrExpiredTokenError
      end

      created_at = ActiveSupport::TimeZone["UTC"].at(decrypted_data["created_at"])
      if as_of.to_f > (created_at + expire_duration).to_f
        raise InvalidOrExpiredTokenError
      end

      decrypted_data
    end

    def self.secret_key
      if Devise.passwordless_secret_key.present?
        Devise.passwordless_secret_key
      else
        Devise.secret_key
      end
    end
  end
end
