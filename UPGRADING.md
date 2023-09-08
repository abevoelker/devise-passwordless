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
  * The routes are no longer pluralized, so change any references like:

    ```ruby
    users_magic_link_url
    ```

    to:

    ```ruby
    user_magic_link_url
    ```

* `Devise::Passwordless::LoginToken` is deprecated.
  * Calls to `::encode` and `::decode` should be replaced with calls to these
    methods on the resource model (e.g. `User`): `#encode_passwordless_token`
    and `::decode_passwordless_token`.
  * References to `Devise::Passwordless::LoginToken.secret_key` should be
    changed to `Devise::Passwordless.secret_key`.

* Hotwire/Turbo support
  * If your Rails app uses Hotwire / Turbo, make sure you're using Devise >= 4.9
    and setting the `config.responder` value in your Devise configuration
    (see Devise Turbo upgrade guide: https://github.com/heartcombo/devise/wiki/How-To:-Upgrade-to-Devise-4.9.0-%5BHotwire-Turbo-integration%5D)

* Resource `#send_magic_link` now uses keyword arguments instead of positional arguments.
  * Change any instances of

    ```ruby
    remember_me = true
    user.send_magic_link(remember_me, subject: "Custom email subject")
    ```

    to:

    ```ruby
    user.send_magic_link(remember_me: true, subject: "Custom email subject")
    ```
