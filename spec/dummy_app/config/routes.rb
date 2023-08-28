Rails.application.routes.draw do
  devise_for :passwordless_users,
    controllers: { sessions: "devise/passwordless/sessions" }
  devise_scope :passwordless_user do
    get "/passwordless_users/magic_link",
      to: "devise/passwordless/magic_links#show",
      as: "passwordless_users_magic_link"
  end
  root to: proc { [200, {}, ['<html />']] }
end
