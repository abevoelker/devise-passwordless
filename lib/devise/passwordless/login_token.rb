module Devise::Passwordless
  class LoginToken
    def self.secret_key
      Devise::Passwordless.deprecator.warn <<-DEPRECATION.strip_heredoc
        [Devise-Passwordless] `Devise::Passwordless::LoginToken.secret_key` is
        deprecated and will be removed in a future release. Please use
        `Devise::Passwordless.secret_key` instead.
      DEPRECATION
      Devise::Passwordless.secret_key
    end
  end
end
