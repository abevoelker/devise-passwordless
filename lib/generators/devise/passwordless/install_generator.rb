require "rails/generators"
require "yaml"

module Devise::Passwordless
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "Updates the Devise initializer to add passwordless config options"

      def update_devise_initializer
        inject_into_file 'config/initializers/devise.rb', before: /^end$/ do <<~'CONFIG'.indent(2)

          # ==> Configuration for :email_authenticatable

          # Need to use a custom Devise mailer in order to send magic links
          config.mailer = "PasswordlessMailer"

          # Time period after a magic login link is sent out that it will be valid for.
          # config.passwordless_login_within = 20.minutes

          # The secret key used to generate passwordless login tokens. The default value
          # is nil, which means defer to Devise's `secret_key` config value. Changing this
          # key will render invalid all existing passwordless login tokens. You can
          # generate your own secret value with e.g. `rake secret`
          # config.passwordless_secret_key = nil
        CONFIG
        end
      end

      def add_custom_devise_mailer
        create_file "app/mailers/passwordless_mailer.rb" do <<~'FILE'
        class PasswordlessMailer < Devise::Mailer
          def magic_link(record, token, remember_me, opts = {})
            @token = token
            @remember_me = remember_me
            devise_mail(record, :magic_link, opts)
          end
        end
        FILE
        end
      end

      def add_mailer_view
        create_file "app/views/devise/mailer/magic_link.html.erb" do <<~'FILE'
          <p>Hello <%= @resource.email %>!</p>

          <p>You can login using the link below:</p>
          
          <p><%= link_to "Log in to my account", send("#{@scope_name.to_s.pluralize}_magic_links_url", Hash[@scope_name, {email: @resource.email, token: @token, remember_me: @remember_me}]) %></p>
          
          <p>Note that the link will expire in <%= Devise.passwordless_login_within.inspect %>.</p>          
        FILE
        end
      end

      def update_devise_yaml
        devise_yaml = "config/locales/devise.en.yml"
        begin
          config = YAML.load_file(devise_yaml)
        rescue Errno::ENOENT
          STDERR.puts "Couldn't find #{devise_yaml} - skipping patch"
          return
        end
        config.deep_merge!({
          en: {
            devise: {
              passwordless: {
                not_found_in_database: "Could not find a user for that email address",
                magic_link_sent: "A login link has been sent to your email address. Please follow the link to log in to your account.",
              },
              failure: {
                passwordless_invalid: "Invalid or expired login link.",
              },
              mailer: {
                magic_link: {
                  subject: "Here's your login link 🪄✨",
                },
              }
            }
          }
        })
        File.open(devise_yaml, "w"){ |f| f.write(config.to_yaml) }
      end
    end
  end
end
