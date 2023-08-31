require "devise/passwordless/version"
require "devise/monkeypatch"
require "devise/passwordless/rails" if defined?(Rails::Engine)
require "devise/models/magic_link_authenticatable"
require "generators/devise/passwordless/install_generator"
