# Devise::Passwordless

A passwordless login strategy for [Devise][]

## Installation

You should already have Devise installed. Then add this gem:

```ruby
gem "devise-passwordless"
```

Then run the generator to automatically update your Devise initializer:

```
rails g devise:passwordless:install
```

Merge these YAML values into your `devise.en.yml` file:

```yaml
en:
  devise:
    failure:
      passwordless_invalid: "Invalid or expired login link."
    mailer:
      passwordless_link:
        subject: "Here's your magic link"
```

## Usage

This gem adds an `:email_authenticatable` strategy that can be used in your Devise models for passwordless authentication. This strategy plays well with most other Devise strategies.

For example, for a User model, you could do this (other strategies optional and not an exhaustive list):

```ruby
class User < ApplicationRecord
  devise :email_authenticatable,
         :registerable,
         :rememberable,
         :validatable,
         :confirmable
end
```

**Note** if using the `:rememberable` strategy for "remember me" functionality, you'll need to add a `remember_token` column to your resource, as there is no password salt to use for validating cookies:

```ruby
change_table :users do |t|
  t.string :remember_token, limit: 20
end
```

**Note** if using the `:confirmable` strategy, you may want to override the default Devise behavior of requiring a fresh login after email confirmation (e.g. [this](https://stackoverflow.com/a/39010334/215168) or [this](https://stackoverflow.com/a/25865526/215168) approach). Otherwise, users will have to get a fresh login link after confirming their email, which makes no sense if they just confirmed they own the email address.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Devise]: https://github.com/heartcombo/devise
