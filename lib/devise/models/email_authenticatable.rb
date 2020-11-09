require 'devise/strategies/email_authenticatable'

module Devise
  module Models
    module EmailAuthenticatable
      extend ActiveSupport::Concern

      def password_required?
        false
      end

      # Not having a password method breaks the :validatable module
      def password
        nil
      end

      # A callback initiated after successfully authenticating. This can be
      # used to insert your own logic that is only run after the user successfully
      # authenticates.
      #
      # Example:
      #
      #   def after_passwordless_authentication
      #     self.update_attribute(:invite_code, nil)
      #   end
      #
      def after_passwordless_authentication
      end

      protected

      module ClassMethods
        # We assume this method already gets the sanitized values from the
        # EmailAuthenticatable strategy. If you are using this method on
        # your own, be sure to sanitize the conditions hash to only include
        # the proper fields.
        def find_for_email_authentication(conditions)
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
