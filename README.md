# Devise::Passwordless

A passwordless a.k.a. "magic link" login strategy for [Devise][]

No database migrations are needed as login links are stateless encrypted tokens generated with Rails's MessageEncryptor.

## Installation

First, install and set up [Devise][].

Then add this gem to your application's Gemfile:

```ruby
gem "devise-passwordless"
```

And then execute:

```
$ bundle install
```

Finally, run the install generator:

```
$ rails g devise:passwordless:install
```

See the [customization section](#customization) for details on what gets installed and how to configure and customize.

## Usage

This gem adds a `:magic_link_authenticatable` strategy that can be used in your Devise models for passwordless authentication. This strategy plays well with most other Devise strategies (see [*notes on other Devise strategies*](#notes-on-other-devise-strategies)).

For example, for a User model, you could do this (other strategies listed are optional and not exhaustive):

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :magic_link_authenticatable,
         :registerable,
         :rememberable,
         :validatable,
         :confirmable
end
```

Then, you'll need to generate two controllers to modify Devise's default session create logic and to handle processing magic links:

```
$ rails g devise:passwordless:controller User
```

Then, set up your Devise routes like so to use these controllers:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }
  devise_scope :user do
    get "/users/magic_links" => "users/magic_links#show"
  end
end
```

Finally, you'll want to update Devise's generated views to remove references to passwords, since you don't need them any more!

These files/directories can be deleted entirely:

```
app/views/devise/passwords
app/views/devise/mailer/password_change.html.erb
app/views/devise/mailer/reset_password_instructions.html.erb
```

And these should be edited to remove password references:

* `app/views/devise/registrations/new.html.erb`
  * Delete fields `:password` and `:password_confirmation`
* `app/views/devise/registrations/edit.html.erb`
  * Delete fields `:password`, `:password_confirmation`, `:current_password`
* `app/views/devise/sessions/new.html.erb`
  * Delete field `:password`

## Customization

Configuration options are stored in Devise's initializer at `config/initializers/devise.rb`:

```ruby
# ==> Configuration for :magic_link_authenticatable

# Need to use a custom Devise mailer in order to send magic links
config.mailer = "PasswordlessMailer"

# Time period after a magic login link is sent out that it will be valid for.
# config.passwordless_login_within = 20.minutes

# The secret key used to generate passwordless login tokens. The default value
# is nil, which means defer to Devise's `secret_key` config value. Changing this
# key will render invalid all existing passwordless login tokens. You can
# generate your own secret value with e.g. `rake secret`
# config.passwordless_secret_key = nil

# When using the :trackable module, set to true to consider magic link tokens
# generated before the user's current sign in time to be expired. In other words,
# each time you sign in, all existing magic links will be considered invalid.
# config.passwordless_expire_old_tokens_on_sign_in = false
```

To customize the magic link email subject line and other status and error messages, modify these values in `config/locales/devise.en.yml`:

```yaml
en:
  devise:
    passwordless:
      not_found_in_database: "Could not find a user for that email address"
      magic_link_sent: "A login link has been sent to your email address. Please follow the link to log in to your account."
    failure:
      magic_link_invalid: "Invalid or expired login link."
    mailer:
      magic_link:
        subject: "Here's your magic login link 🪄✨"
```

To customize the magic link email body, edit `app/views/devise/mailer/magic_link.html.erb`

### Notes on other Devise strategies

If using the `:rememberable` strategy for "remember me" functionality, you'll need to add a `remember_token` column to your resource, as by default it assumes you're using a password strategy and relies on comparing the password's salt to validate cookies:

```ruby
change_table :users do |t|
  t.string :remember_token, limit: 20
end
```

If using the `:confirmable` strategy, you may want to override the default Devise behavior of requiring a fresh login after email confirmation (e.g. [this](https://stackoverflow.com/a/39010334/215168) or [this](https://stackoverflow.com/a/25865526/215168) approach). Otherwise, users will have to get a fresh login link after confirming their email, which makes little sense if they just confirmed they own the email address.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Devise]: https://github.com/heartcombo/devise
