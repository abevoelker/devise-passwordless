require "rails/generators"
require "yaml"

module Devise::Passwordless
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
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

      def update_devise_yaml
        devise_yaml = "config/locales/devise.en.yml"
        begin
          config = YAML.load_file(devise_yaml)
        rescue Errno::ENOENT
          STDERR.puts "Couldn't find devise.en.yml - skipping patch"
          return
        end
        config["en"]["devise"]["failure"]["passwordless_invalid"] = "Invalid or expired login link."
        config["en"]["devise"]["mailer"]["passwordless_link"] = {subject: "Your login link"}
        File.open(devise_yaml, "w") do |f|
          f.write(config.to_yaml)
        end
      end
    end
  end
end
