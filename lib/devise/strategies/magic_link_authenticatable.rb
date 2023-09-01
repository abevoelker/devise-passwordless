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
        resource_class = mapping.to

        begin
          resource, extra = resource_class.decode_passwordless_token(token, resource_class)
        rescue Devise::Passwordless::InvalidOrExpiredTokenError
          fail!(:magic_link_invalid)
          return
        end

        if validate(resource)
          remember_me(resource)
          resource.after_magic_link_authentication
          env['warden.magic_link_extra'] = extra.fetch('data', {}).delete('extra')
          success!(resource)
        else
          fail!(:magic_link_invalid)
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

Warden::Strategies.add(:magic_link_authenticatable, Devise::Strategies::MagicLinkAuthenticatable)
