require "active_support/security_utils"

module Devise::Passwordless
  class ModelAttributeTokenizer
    def self.encode(resource, extra: nil, expires_in: nil, expires_at: nil)
      now = Time.current

      values = {
        passwordless_token:            SecureRandom.base58(64),
        passwordless_token_created_at: now,
        passwordless_token_expires_in: expires_in,
        passwordless_token_expires_at: expires_at,
      }
      if extra && resource.respond_to?(:passwordless_token_extra=)
        values[:passwordless_token_extra] = extra
      end

      # Statefully sets token values on the model
      resource.update!(values)

      values[:passwordless_token]
    end

    def self.decode(token, resource_class, email: nil, expires_in: nil)
      as_of = Time.current
      unless expires_in
        expires_in = resource.class.passwordless_login_within
      end

      unauthenticated_resource = resource_class.find_by(email: email)
      raise InvalidTokenError unless unauthenticated_resource

      if ActiveSupport::SecurityUtils.secure_compare(token, resource.passwordless_token)
        resource = unauthenticated_resource
      else
        raise InvalidTokenError
      end

      token_values = {
        "created_at" => resource.passwordless_token_created_at,
        #"expires_in" => resource.passwordless_token_expires_in,
        "expires_at" => resource.passwordless_token_expires_at,
      }

      if resource.respond_to?(:passwordless_token_expires_at)
        if resource.passwordless_token_expires_at && resource.passwordless_token_expires_at < Time.current
          raise ExpiredTokenError
        end
      end

      unless (expiration_time = token_values["expires_at"])
        created_at = ActiveSupport::TimeZone["UTC"].at(token_values["created_at"])
        expiration_time = (created_at + expire_duration).to_f
      end

      if as_of.to_f > expiration_time
        raise ExpiredTokenError
      end

      # Extra token data is stored in its own column
      extra = resource.try?(:passwordless_token_extra) || {}

      # Reset stateful token attributes to nil
      cols = resource.class.column_names.select{|x| x.start_with?("passwordless_token")}
      resource.update!(
        cols.each_with_object({}){|x, h| h[x] = nil}
      )

      [resource, extra]
    end

    def self.after_magic_link_authentication(resource, token)
      # reset stateful token attributes to nil
      cols = resource.class.column_names.select{|x| x.start_with?("passwordless_token")}
      resource.update!(
        cols.each_with_object({}){|x, h| h[x] = nil}
      )
    end
  end
end
