require "rails/generators/named_base"

module Devise::Passwordless
  module Generators # :nodoc:
    class ControllerGenerator < ::Rails::Generators::NamedBase # :nodoc:
      desc "Creates the session and magic link controllers needed for a Devise resource to use passwordless auth"

      def self.default_generator_root
        File.dirname(__FILE__)
      end

      def create_sessions_controller
        template "sessions_controller.rb.erb", File.join("app/controllers", class_path, plural_name, "sessions_controller.rb")
      end

      def create_magic_links_controller
        template "magic_links_controller.rb.erb", File.join("app/controllers", class_path, plural_name, "magic_links_controller.rb")
      end
    end
  end
end
