require "rails/generators/named_base"

module Devise::Passwordless
  module Generators
    class InstallGenerator < ::Rails::Generators::NamedBase
      desc "Updates the Devise initializer to add passwordless config options"
      def update_devise_initializer
        inject_into_file 'config/initializers/devise.rb', before: /^end$/ do <<~'CONFIG'.indent(2)

          # ==> Configuration for :email_authenticatable

          # Time period after a magic login link is sent out that it will be valid for.
          # config.passwordless_login_within = 20.minutes
        
          # The secret key used to generate passwordless login tokens. The default
          # value is nil, which means defer to Devise's `secret_key` config value.
          # Changing this key will render invalid all existing passwordless login
          # tokens. You can generate your own value with e.g. `rake secret`
          # config.passwordless_secret_key = nil
        CONFIG
        end
      end
    end
  end
end
