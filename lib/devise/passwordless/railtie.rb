module Devise::Passwordless
  class Railtie < Rails::Railtie
    config.after_initialize do
      require "devise/passwordless/routing"
      require "devise/magic_links_controller"

      Devise.add_module(:magic_link_authenticatable, {
        model: true,
        strategy: true,
        route: { magic_link: [nil, :show], session: [nil, :new, :destroy] },
        controller: :sessions,
      })

      require "devise/passwordless/mailer"
    end
  end
end
