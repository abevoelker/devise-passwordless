require "devise"
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

    FILTER_PARAMS_WARNING = "[DEVISE-PASSWORDLESS] We have detected that your Rails configuration does not " \
                            "filter :token parameters out of your logs. You should append :token to your " \
                            "config.filter_parameters Rails setting so that magic link tokens don't " \
                            "leak out of your logs."

    def self.check_filter_parameters(params)
      begin
        unless params.find{|p| p.to_sym == :token}
          warn FILTER_PARAMS_WARNING
        end
      # Cancel the check if filter_parameters contains regular expressions or other exotic values
      rescue NoMethodError
        return
      end
    end
  end
end
