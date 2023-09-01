require "psych"
require "rails/generators"
require "yaml"

module Devise::Passwordless
  module Generators # :nodoc:
    class InstallGenerator < ::Rails::Generators::Base # :nodoc:
      desc "Creates default install and config files for the Devise :magic_link_authenticatable strategy"

      def self.default_generator_root
        File.dirname(__FILE__)
      end

      def update_devise_initializer
        inject_into_file 'config/initializers/devise.rb', before: /^end$/ do <<~'CONFIG'.indent(2)

          # ==> Configuration for :magic_link_authenticatable

          # Need to use a custom Devise mailer in order to send magic links
          config.mailer = "Devise::Passwordless::Mailer"

          # Which algorithm to use for tokenizing magic links. See README for descriptions
          config.passwordless_tokenizer = "SignedGlobalIDTokenizer"

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

      def add_mailer_view
        create_file "app/views/devise/mailer/magic_link.html.erb" do <<~'FILE'
          <p>Hello <%= @resource.email %>!</p>

          <p>You can login using the link below:</p>
          
          <p><%= link_to "Log in to my account", magic_link_url(@resource, @scope_name => {email: @resource.email, token: @token, remember_me: @remember_me}) %></p>
          
          <p>Note that the link will expire in <%= Devise.passwordless_login_within.inspect %>.</p>          
        FILE
        end
      end

      def update_devise_yaml
        devise_yaml = "config/locales/devise.en.yml"
        existing_config = {}
        begin
          in_root do
            existing_config = YAML.load_file(devise_yaml)
          end
        rescue Errno::ENOENT
          say_status :skip, devise_yaml, :yellow
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
        merged_config = existing_config.deep_merge(default_config.deep_stringify_keys)
        if existing_config.to_yaml == merged_config.to_yaml
          say_status :identical, devise_yaml, :blue
        else
          in_root do
            File.open(devise_yaml, "w") do |f|
              f.write(force_double_quote_yaml(merged_config.to_yaml))
            end
          end
          say_status :insert, devise_yaml, :green
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
