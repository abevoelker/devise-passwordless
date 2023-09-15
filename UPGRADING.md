## Upgrading from 0.x to 1.0

⭐ The 1.0 release includes significant breaking changes! ⭐

This is a big release that cleans up the DX quite a bit. 🎉 Make these changes
to have a successful upgrade:

* Generated `MagicLinksController` is no longer required
  * Delete `app/controllers/devise/passwordless/magic_links_controller.rb`
* Generated `SessionsController` is no longer required
  * If you haven't customized the generated controller in:

    ```
    app/controllers/devise/passwordless/sessions_controller.rb
    ```

    then go ahead and delete the file!
  * If you **have** customized the controller, then we're going to move it. Move the file to somewhere like

    ```
    app/controllers/custom_sessions_controller.rb
    ```

    And change the inside class definition to match, e.g. from

    ```ruby
    class Devise::Passwordless::SessionsController < Devise::SessionsController
    ```

    to

    ```ruby
    class CustomSessionsController < Devise::Passwordless::SessionsController
    ```

    Then, change the route of your resource to match it:

    ```ruby
    devise_for :users,
      controllers: { sessions: "custom_sessions" }
    ```

    Finally, you should review the latest source of
    `Devise::Passwordless::SessionsController` as its implementation has changed,
    so you'll want to sync up your customizations.
* Routing no longer requires custom `devise_scope` for magic links
  * Delete any route declarations from `config/routes.rb` that look like this:

    ```ruby
    devise_scope :user do
      get "/users/magic_link",
        to: "devise/passwordless/magic_links#show",
        as: "users_magic_link"
    ```

* Changes are required to the Devise initializer in `config/initializers/devise.rb`:
  * Delete this line:
    ```
    require 'devise/passwordless/mailer'
    ```
  * New config value `passwordless_tokenizer` is required. Check README for
    an explanation of tokenizers.
    * Add this section to `config/initializers/devise.rb`:

      ```ruby
      # Which algorithm to use for tokenizing magic links. See README for descriptions
      config.passwordless_tokenizer = "MessageEncryptorTokenizer"
      ```

* There is a new `:magic_link_sent_paranoid` i18n key you should add to your `config/locales/devise.en.yml` file:

    ```diff
    @@ -58,6 +58,7 @@
        passwordless:
          not_found_in_database: "Could not find a user for that email address"
          magic_link_sent: "A login link has been sent to your email address. Please follow the link to log in to your account."
    +      magic_link_sent_paranoid: "If your account exists, you will receive an email with a login link. Please follow the link to log in to your account."
      errors:
        messages:
          already_confirmed: "was already confirmed, please try signing in"

    ```
  * If Devise's paranoid mode is enabled in your Devise initializer, this new key
    replaces the use of both `:magic_link_sent` and `:not_found_in_database` to be
    ambiguous about the existence of user accounts to prevent account enumeration
    vulnerabilities. If you want the old behavior back, ensure `Devise.paranoid`
    is `false` by setting `config.paranoid = false` in your Devise initializer.

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

* The `#send_magic_link` method now uses keyword arguments instead of positional arguments.
  * Change any instances of

    ```ruby
    remember_me = true
    user.send_magic_link(remember_me, subject: "Custom email subject")
    ```

    to:

    ```ruby
    user.send_magic_link(remember_me: true, subject: "Custom email subject")
    ```

* After sending a magic link, users will now be redirected rather than
  re-rendering the sign-in form.
  * [See the README][after-magic-link-sent-readme] for details on how to customize the redirect behavior

[after-magic-link-sent-readme]: https://github.com/abevoelker/devise-passwordless#redirecting-after-magic-link-is-sent
