## Upgrading from 0.x to 1.0

This is a big release that cleans up the DX quite a bit! 🎉 Make these changes
to have a successful upgrade:

* Generated `SessionsController` is no longer required
  * Delete `app/controllers/devise/passwordless/sessions_controller.rb`
* Generated `MagicLinksController` is no longer required
  * Delete `app/controllers/devise/passwordless/magic_links_controller.rb`
* Routing no longer requires custom `devise_scope` for magic links
  * Delete any route declarations from `config/routes.rb` that look like this:

    ```ruby
    devise_scope :user do
      get "/users/magic_link",
        to: "devise/passwordless/magic_links#show",
        as: "users_magic_link"
    ```

* New Devise config value `passwordless_tokenizer` is required. Check README for
  an explanation of tokenizers.
  * Add this section to `config/initializers/devise.rb`:

    ```ruby
    # Which algorithm to use for tokenizing magic links. See README for descriptions
    config.passwordless_tokenizer = "MessageEncryptorTokenizer"
    ```

* `magic_link` path and URL helpers now work
  * Delete any code that looks like this:

    ```ruby
    send("#{@scope_name.to_s.pluralize}_magic_link_url", Hash[@scope_name, {email: @resource.email, token: @token, remember_me: @remember_me}])
    ```

    and replace it with this:

    ```ruby
    magic_link_url(@resource, @scope_name => {email: @resource.email, token: @token, remember_me: @remember_me})
    ```

* `Devise::Passwordless::LoginToken` is deprecated.
  * Calls to `::encode` and `::decode` should be replaced with calls to these
    methods on the resource model (e.g. `User`): `#encode_passwordless_token`
    and `::decode_passwordless_token`.
  * References to `Devise::Passwordless::LoginToken.secret_key` should be
    changed to `Devise::Passwordless.secret_key`.
