require "devise/passwordless/version"
require "devise/monkeypatch"
require "devise/passwordless/rails" if defined?(Rails::Engine)
require "devise/models/magic_link_authenticatable"
require "generators/devise/passwordless/install_generator"
require "devise/passwordless/tokenizers/message_encryptor_tokenizer"
require "devise/passwordless/tokenizers/signed_global_id_tokenizer"

module Devise
  module Passwordless
    class InvalidOrExpiredTokenError < StandardError; end
    class InvalidTokenError < InvalidOrExpiredTokenError; end
    class ExpiredTokenError < InvalidOrExpiredTokenError; end

    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("1.1", "Devise-Passwordless")
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
