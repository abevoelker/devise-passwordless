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

      ::Devise::Passwordless.check_filter_parameters(params)
    end
  end
end
