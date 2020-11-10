# Devise::Passwordless

A passwordless a.k.a. "magic link" login strategy for [Devise][]

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

Next, run the generator to automatically update your Devise initializer:

```
$ rails g devise:passwordless:install
```

See the [customization section](#customization) for details on what gets installed and how to configure and customize your installation.

## Usage

This gem adds an `:email_authenticatable` strategy that can be used in your Devise models for passwordless authentication. This strategy plays well with most other Devise strategies (see [*notes on other Devise strategies*](#notes-on-other-strategies)).

For example, for a User model, you could do this (other strategies listed are optional and not exhaustive):

```ruby
class User < ApplicationRecord
  devise :email_authenticatable,
         :registerable,
         :rememberable,
         :validatable,
         :confirmable
end
```

You'll need to add two routes to accommodate generating emailed login links, and then consuming the links:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  devise_scope :user do
    get "/passwordless_login" => "devise/sessions#create", as: :passwordless_login
  end
end
```

## Customization

The installation generator copies the following configuration to `config/initializers/devise.rb`, which you may modify to customize behavior:

```ruby
# Time period after a magic login link is sent out that it will be valid for.
# config.passwordless_login_within = 20.minutes

# The secret key used to generate passwordless login tokens. The default
# value is nil, which means defer to Devise's `secret_key` config value.
# Changing this key will render invalid all existing passwordless login
# tokens. You can generate your own value with e.g. `rake secret`
# config.passwordless_secret_key = nil
```

The generator copies a default view to `app/views/devise/mailer/passwordless_link.html.erb` that is used when sending emails with login links. This view relies on the existence of a `passwordless_login` route like defined in the [*usage* section example](#usage), so if you use a different route name you must modify the view.

The generator will also attempt to merge the following YAML values into your `config/locales/devise.en.yml` file, which you may modify:

```yaml
en:
  devise:
    failure:
      passwordless_invalid: "Invalid or expired login link."
    mailer:
      passwordless_link:
        subject: "Here's your login link"
```

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
