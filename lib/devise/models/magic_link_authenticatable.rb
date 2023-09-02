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

      def encode_passwordless_token(*args)
        self.class.passwordless_tokenizer_class.encode(self, *args)
      end

      def send_magic_link(remember_me, opts = {})
        token = self.encode_passwordless_token
        send_devise_notification(:magic_link, token, remember_me, opts)
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
        def passwordless_tokenizer_class
          @passwordless_tokenizer_class ||= self.passwordless_tokenizer.is_a?(Class) ? (
            self.passwordless_tokenizer
          ) : (
            self.passwordless_tokenizer.start_with?("::") ? (
              self.passwordless_tokenizer.constantize
            ) : (
              "Devise::Passwordless::#{self.passwordless_tokenizer}".constantize
            )
          )
        end

        def decode_passwordless_token(*args)
          passwordless_tokenizer_class.decode(*args)
        end

        # We assume this method already gets the sanitized values from the
        # MagicLinkAuthenticatable strategy. If you are using this method on
        # your own, be sure to sanitize the conditions hash to only include
        # the proper fields.
        def find_for_magic_link_authentication(conditions)
          find_for_authentication(conditions)
        end

        Devise::Models.config(self,
          :passwordless_tokenizer,
          :passwordless_login_within,
          #:passwordless_secret_key,
          :passwordless_expire_old_tokens_on_sign_in
        )
      end
    end
  end
end

module Devise
  mattr_accessor :passwordless_tokenizer
  @@passwordless_tokenizer = nil
  def self.passwordless_tokenizer
    if @@passwordless_tokenizer.blank?
      Devise::Passwordless.deprecator.warn <<-DEPRECATION.strip_heredoc
        [Devise-Passwordless] `Devise.passwordless_tokenizer` is a required
        config option. If you are upgrading to Devise-Passwordless 1.0 from
        a previous install, you should use "MessageEncryptorTokenizer" for
        backwards compatibility. New installs are templated with
        "SignedGlobalIDTokenizer". Read the README for a comparison of
        options and UPGRADING for upgrade instructions. Execution will
        now proceed with a value of "MessageEncryptorTokenizer" but future
        releases will raise an error if this option is unset.
      DEPRECATION

      "MessageEncryptorTokenizer"
    else
      @@passwordless_tokenizer
    end
  end

  mattr_accessor :passwordless_login_within
  @@passwordless_login_within = 20.minutes

  mattr_accessor :passwordless_secret_key
  @@passwordless_secret_key = nil

  mattr_accessor :passwordless_expire_old_tokens_on_sign_in
  @@passwordless_expire_old_tokens_on_sign_in = false
end
