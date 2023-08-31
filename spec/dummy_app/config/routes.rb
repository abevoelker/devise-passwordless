Rails.application.routes.draw do
  # Passwordless users with :confirmable behavior
  # (users are logged out until they confirm their email address)
  devise_for :passwordless_confirmable_users,
    controllers: { sessions: "devise/passwordless/sessions" }

  # Passwordless users without :confirmable behavior
  # (users are immediately signed-in after signing up)
  devise_for :passwordless_users,
    controllers: { sessions: "devise/passwordless/sessions" }

  root to: "welcome#index"
end
