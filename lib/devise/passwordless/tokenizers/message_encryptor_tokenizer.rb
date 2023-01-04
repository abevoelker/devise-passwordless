module Devise::Passwordless
  class MessageEncryptorTokenizer
    def self.encode(resource, extra: nil, expires_at: nil)
      now = Time.current
      len = ActiveSupport::MessageEncryptor.key_len
      salt = SecureRandom.random_bytes(len)
      key = ActiveSupport::KeyGenerator.new(Devise::Passwordless.secret_key).generate_key(salt, len)
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
      data[:expires_at] = expires_at.to_f if expires_at
      encrypted_data = crypt.encrypt_and_sign(data)
      salt_base64 = Base64.strict_encode64(salt)
      "#{salt_base64}:#{encrypted_data}"
    end

    def self.decode(token, resource_class, as_of: Time.current, expire_duration: Devise.passwordless_login_within)
      raise InvalidTokenError if token.blank?
      salt_base64, encrypted_data = token.split(":")
      raise InvalidTokenError if salt_base64.blank? || encrypted_data.blank?
      begin
        salt = Base64.strict_decode64(salt_base64)
      rescue ArgumentError
        raise InvalidTokenError
      end
      len = ActiveSupport::MessageEncryptor.key_len
      key = ActiveSupport::KeyGenerator.new(Devise::Passwordless.secret_key).generate_key(salt, len)
      crypt = ActiveSupport::MessageEncryptor.new(key, serializer: JSON)
      begin
        decrypted_data = crypt.decrypt_and_verify(encrypted_data)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
        raise InvalidTokenError
      end

      expiration_time = decrypted_data["expires_at"]
      if expiration_time.nil?
        created_at = ActiveSupport::TimeZone["UTC"].at(decrypted_data["created_at"])
        expiration_time = (created_at + expire_duration).to_f
      end

      if as_of.to_f > expiration_time
        raise ExpiredTokenError
      end

      resource = resource_class.find_by(id: decrypted_data["data"]["resource"]["key"])

      if resource_class.passwordless_expire_old_tokens_on_sign_in
        if (last_login = resource.try(:current_sign_in_at))
          token_created_at = ActiveSupport::TimeZone["UTC"].at(decrypted_data["created_at"])
          if token_created_at < last_login
            raise ExpiredTokenError
          end
        end
      end

      [resource, decrypted_data]
    end
  end
end
