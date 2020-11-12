require "psych"
require "rails/generators"
require "yaml"

module Devise::Passwordless
  module Generators # :nodoc:
    class InstallGenerator < ::Rails::Generators::Base # :nodoc:
      desc "Creates default install and config files for the Devise passwordless auth strategy"

      def update_devise_initializer
        inject_into_file 'config/initializers/devise.rb', before: /^end$/ do <<~'CONFIG'.indent(2)

          # ==> Configuration for :magic_link_authenticatable

          # Need to use a custom Devise mailer in order to send magic links
          config.mailer = "PasswordlessMailer"

          # Time period after a magic login link is sent out that it will be valid for.
          # config.passwordless_login_within = 20.minutes

          # The secret key used to generate passwordless login tokens. The default value
          # is nil, which means defer to Devise's `secret_key` config value. Changing this
          # key will render invalid all existing passwordless login tokens. You can
          # generate your own secret value with e.g. `rake secret`
          # config.passwordless_secret_key = nil

          # When using the :trackable module, set to true to consider magic link tokens
          # generated before the user's current sign in time to be expired. In other words,
          # each time you sign in, all existing magic links will be considered invalid.
          # config.passwordless_expire_old_tokens_on_sign_in = false
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
        default_config = {
          en: {
            devise: {
              passwordless: {
                not_found_in_database: "Could not find a user for that email address",
                magic_link_sent: "A login link has been sent to your email address. Please follow the link to log in to your account.",
              },
              failure: {
                magic_link_invalid: "Invalid or expired login link.",
              },
              mailer: {
                magic_link: {
                  subject: "Here's your magic login link ✨",
                },
              }
            }
          }
        }
        merged_config = config.deep_merge(default_config.deep_stringify_keys)
        File.open(devise_yaml, "w") do |f|
          f.write(force_double_quote_yaml(merged_config.to_yaml))
        end
      end

      private

      # https://github.com/ruby/psych/issues/322#issuecomment-328408276
      def force_double_quote_yaml(yaml_str)
        ast = Psych.parse_stream(yaml_str)

        # First pass, quote everything
        ast.grep(Psych::Nodes::Scalar).each do |node|
          node.plain  = false
          node.quoted = true
          node.style  = Psych::Nodes::Scalar::DOUBLE_QUOTED
        end

        # Second pass, unquote keys
        ast.grep(Psych::Nodes::Mapping).each do |node|
          node.children.each_slice(2) do |k, _|
            k.plain  = true
            k.quoted = false
            k.style  = Psych::Nodes::Scalar::ANY
          end
        end

        ast.yaml(nil, {line_width: -1})
      end
    end
  end
end
