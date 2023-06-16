# frozen_string_literal: true

require "devise"
require "devise/strategies/authenticatable"
require "devise/passwordless/login_token"

module Devise
  module Strategies
    class MagicLinkAuthenticatable < Authenticatable
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
        begin
          data = decode_passwordless_token
        rescue Devise::Passwordless::LoginToken::ExpiredTokenError
          # Send a new token
          if Devise.passwordless_auto_refresh_expired_login_links
            # Send a new login link email
            resource = mapping.to.find_by(id: data["data"]["resource"]["key"])
            if resource && Devise.passwordless_auto_refresh_expired_login_links
              resource.send_magic_link(true)
              fail!(:magic_link_refresh)
            else
              fail!(:magic_link_invalid)
            end

          else
            fail!(:magic_link_invalid)
          end

          return
        rescue Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError
          fail!(:magic_link_invalid)
          return
        end

        resource = mapping.to.find_by(id: data["data"]["resource"]["key"])

        if resource && Devise.passwordless_expire_old_tokens_on_sign_in
          if (last_login = resource.try(:current_sign_in_at))
            token_created_at = ActiveSupport::TimeZone["UTC"].at(data["created_at"])
            if token_created_at < last_login
              fail!(:magic_link_invalid)
              return
            end
          end
        end

        if validate(resource)
          remember_me(resource)
          resource.after_magic_link_authentication
          success!(resource)
        else
          fail!(:magic_link_invalid)
        end
      end

      private

      def decode_passwordless_token
        Devise::Passwordless::LoginToken.decode(self.token)
      end

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

Warden::Strategies.add(:magic_link_authenticatable, Devise::Strategies::MagicLinkAuthenticatable)

Devise.add_module(:magic_link_authenticatable, {
  strategy: true,
  controller: :sessions,
  route: :session,
  model: "devise/models/magic_link_authenticatable",
})
