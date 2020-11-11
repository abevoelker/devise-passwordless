require 'devise/strategies/magic_link_authenticatable'

module Devise
  module Models
    module MagicLinkAuthenticatable
      extend ActiveSupport::Concern

      def password_required?
        false
      end

      # Not having a password method breaks the :validatable module
      def password
        nil
      end

      def send_magic_link(remember_me)
        token = Devise::Passwordless::LoginToken.encode(self)
        send_devise_notification(:magic_link, token, remember_me, {})
      end

      # A callback initiated after successfully authenticating. This can be
      # used to insert your own logic that is only run after the user successfully
      # authenticates.
      #
      # Example:
      #
      #   def after_magic_link_authentication
      #     self.update_attribute(:invite_code, nil)
      #   end
      #
      def after_magic_link_authentication
      end

      protected

      module ClassMethods
        # We assume this method already gets the sanitized values from the
        # MagicLinkAuthenticatable strategy. If you are using this method on
        # your own, be sure to sanitize the conditions hash to only include
        # the proper fields.
        def find_for_magic_link_authentication(conditions)
          find_for_authentication(conditions)
        end

        Devise::Models.config(self, :passwordless_login_within, :passwordless_secret_key)
      end
    end
  end
end

module Devise
  mattr_accessor :passwordless_login_within
  @@passwordless_login_within = 20.minutes

  mattr_accessor :passwordless_secret_key
  @@passwordless_secret_key = nil
end
