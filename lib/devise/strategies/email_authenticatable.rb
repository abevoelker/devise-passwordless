# frozen_string_literal: true

require "devise"
require "devise/strategies/authenticatable"
require "devise/passwordless/login_token"

module Devise
  module Strategies
    class EmailAuthenticatable < Authenticatable
      #undef :password
      #undef :password=
      attr_accessor :token

      def valid_for_http_auth?
        super && http_auth_hash[:token].present?
      end

      def valid_for_params_auth?
        super && params_auth_hash[:token].present?
      end

      def authenticate!
        data = begin
          x = Devise::Passwordless::LoginToken.decode(self.token)
          x["data"]
        rescue Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError
          fail!(:passwordless_invalid)
          return
        end

        resource = mapping.to.find_by(id: data["resource"]["key"])
        if validate(resource)
          remember_me(resource)
          resource.after_passwordless_authentication
          success!(resource)
        else
          fail!(:passwordless_invalid)
        end
      end

      private

      # Sets the authentication hash and the token from params_auth_hash or http_auth_hash.
      def with_authentication_hash(auth_type, auth_values)
        self.authentication_hash, self.authentication_type = {}, auth_type
        self.token = auth_values[:token]

        parse_authentication_key_values(auth_values, authentication_keys) &&
        parse_authentication_key_values(request_values, request_keys)
      end
    end
  end
end

Warden::Strategies.add(:email_authenticatable, Devise::Strategies::EmailAuthenticatable)

Devise.add_module(:email_authenticatable, {
  strategy: true,
  controller: :sessions,
  model: "devise/models/email_authenticatable",
  route: :session
})
