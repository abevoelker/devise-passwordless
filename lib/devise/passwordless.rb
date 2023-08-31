require "devise/passwordless/version"
require "devise/monkeypatch"
require "devise/passwordless/railtie" if defined?(Rails::Railtie)
require "devise/models/magic_link_authenticatable"
require "generators/devise/passwordless/install_generator"
