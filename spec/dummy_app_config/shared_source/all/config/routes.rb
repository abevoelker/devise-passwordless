Rails.application.routes.draw do
  devise_for :password_users
  # Passwordless users with :confirmable behavior
  # (users are logged out until they confirm their email address)
  devise_for :passwordless_confirmable_users,
    controllers: { sessions: "devise/passwordless/sessions" }

  # Passwordless users without :confirmable behavior
  # (users are immediately signed-in after signing up)
  devise_for :passwordless_users,
    controllers: { sessions: "devise/passwordless/sessions" }

  # Set up a namespace for testing custom controllers
  namespace "test_custom_controllers" do
    devise_for :passwordless_users,
      controllers: {
        sessions: "custom_sessions",
        magic_links: "custom_magic_links"
      }
    get "foo", to: ->(env) { [200, {}, ["foo"]] }
    get "bar", to: ->(env) { [200, {}, ["bar"]] }
  end
  # Set up a namespace for testing custom after_magic_link_sent_path_for
  namespace "test_custom_after_magic_link_sent_redirect" do
    devise_for :passwordless_users,
      controllers: {
        sessions: "after_magic_link_sent_sessions"
      }
    get "baz", to: ->(env) { [200, {}, ["baz"]] }
  end

  root to: "welcome#index"
end
