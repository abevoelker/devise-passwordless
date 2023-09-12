module Devise::Passwordless
  class Engine < Rails::Engine
    initializer "devise_passwordless.routing" do
      require "devise/passwordless/routing"

      Devise.add_module(:magic_link_authenticatable, {
        model: true,
        strategy: true,
        route: { magic_link: [nil, :show], session: [nil, :new, :destroy] },
        controller: :sessions,
      })
    end

    initializer "devise_passwordless.log_filter_check" do
      params = Rails.try(:application).try(:config).try(:filter_parameters) || []

      unless params.map(&:to_sym).include?(:token)
        warn "[DEVISE-PASSWORDLESS] We have detected that your Rails configuration does not " \
              "filter :token parameters out of your logs. You should append :token to your " \
              "config.filter_parameters Rails setting so that magic link tokens don't " \
              "leak out of your logs."
      end
    end
  end
end
