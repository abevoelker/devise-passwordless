Rails.application.routes.draw do
  # Passwordless users with :confirmable behavior
  # (users are logged out until they confirm their email address)
  devise_for :passwordless_confirmable_users,
    controllers: { sessions: "devise/passwordless/sessions" }
  devise_scope :passwordless_confirmable_user do
    get "/passwordless_confirmable_users/magic_link",
      to: "devise/passwordless/magic_links#show",
      as: "passwordless_confirmable_users_magic_link"
  end

  # Passwordless users without :confirmable behavior
  # (users are immediately signed-in after signing up)
  devise_for :passwordless_users,
    controllers: { sessions: "devise/passwordless/sessions" }
  devise_scope :passwordless_user do
    get "/passwordless_users/magic_link",
      to: "devise/passwordless/magic_links#show",
      as: "passwordless_users_magic_link"
  end
  root to: "welcome#index"
end
