# Devise::Passwordless

A passwordless a.k.a. "magic link" login strategy for [Devise][]

## Features

* No database changes needed - magic links are stateless tokens
* [Choose your token encoding algorithm or easily write your own](#tokenizers)
* [Supports multiple user (resource) types](#multiple-user-resource-types)
* All the goodness of Devise!

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

For example, if your Devise model is User, enable the strategy like this:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :magic_link_authenticatable #, :registerable, :rememberable, ...
end
```

Then, change your route to process sessions using the passwordless sessions controller:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users,
    controllers: { sessions: "devise/passwordless/sessions" }
end
```

Finally, you'll want to update Devise's generated views to remove references to passwords, since you don't need them anymore!

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

#### Manually sending magic links

You can very easily send a magic link at any point like so:

```ruby
remember_me = true
User.last.send_magic_link(remember_me)
```

## Customization

Configuration options are stored in Devise's initializer at `config/initializers/devise.rb`:

```ruby
# ==> Configuration for :magic_link_authenticatable

# Need to use a custom Devise mailer in order to send magic links.
# If you're already using a custom mailer just have it inherit from
# Devise::Passwordless::Mailer instead of Devise::Mailer
config.mailer = "Devise::Passwordless::Mailer"

# Which algorithm to use for tokenizing magic links. See README for descriptions
config.passwordless_tokenizer = "SignedGlobalIDTokenizer"

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

Most config options can be set on a per-model basis. For instance,
you can use different tokenizers across different models like so:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :magic_link_authenticatable

  def self.passwordless_tokenizer
    "SignedGlobalIDTokenizer"
  end
end

# app/models/another_user.rb
class AnotherUser < ApplicationRecord
  devise :magic_link_authenticatable

  def self.passwordless_tokenizer
    "MessageEncryptorTokenizer"
  end
  def self.passwordless_login_within
    1.hour
  end
end
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
        subject: "Here's your magic login link ✨"
```

To customize the magic link email body, edit `app/views/devise/mailer/magic_link.html.erb`

To customise email headers (including the email subject as well as more unusual headers like `X-Entity-Ref-ID`) pass them in a hash to `resource.send_magic_link` in `SessionsController`, eg. `resource.send_magic_link(create_params[:remember_me], subject: "Your login link has arrived!")`.

## Tokenizers

The algorithm used to encode and decode tokens can be fully customized and swapped
out on a per-model basis.

### SignedGlobalIDTokenizer

Tokens are [Rails signed Global IDs][globalid]. This is the default for new installs.

Reasons to use or not use:

* The implementation is short and simple, so less likely to be buggy
* Should work with all ORMs that implement GlobalID support
* Cannot add arbitrary metadata to generated tokens
* Tokens are signed, not encrypted, so some data will be visible when base64-decoded
* Tokens tend to be a little longer (~30 chars IME) than MessageEncryptors'

[globalid]: https://github.com/rails/globalid

### MessageEncryptorTokenizer

Tokens are encrypted using Rails's [MessageEncryptor][].

[MessageEncryptor]: https://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html

Reasons to use or not use:

* This was the only tokenizer in previous library versions
* The implementation is longer and more involved than SignedGlobalID
* Written with ActiveRecord in mind but may work with other ORMs
* Can add arbitrary extra metadata to tokens
* Tokens are opaque, due to being encrypted - no data visible when base64-decoded
* Tokens tend to be a little shorter than SignedGlobalID IME

### Your own custom tokenizer

It's straightforward to write your own tokenizer class; it just needs to respond to
`::encode` and `::decode`:

```ruby
class LuckyUserTokenizer
  def self.encode(resource, *args)
    "8" * 88 # our token is always lucky!
  end

  def self.decode(token, resource_class, *args)
    # ignore token and retrieve a random user
    resource_class.order("RANDOM()").limit(1).first
  end
end

# config/initializers/devise.rb
config.passwordless_tokenizer = "::LuckyUserTokenizer"
```

### Multiple user (resource) types

Devise supports multiple resource types, so we do too.

For example, if you have a User and Admin model, enable the `:magic_link_authenticatable` strategy for each:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :magic_link_authenticatable # , :registerable, :rememberable, ...
end

# app/models/admin.rb
class Admin < ApplicationRecord
  devise :magic_link_authenticatable # , :registerable, :rememberable, ...
end
```

Then just set up your routes like this:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users,
    controllers: { sessions: "devise/passwordless/sessions" }
  devise_for :admins,
    controllers: { sessions: "devise/passwordless/sessions" }
end
```

And that's it!

Messaging can be customized per-resource using [Devise's usual I18n support][devise-i18n]:

```yaml
en:
  devise:
    passwordless:
      user:
        not_found_in_database: "Could not find a USER for that email address"
        magic_link_sent: "A USER login link has been sent to your email address. Please follow the link to log in to your account."
      admin:
        not_found_in_database: "Could not find an ADMIN for that email address"
        magic_link_sent: "An ADMIN login link has been sent to your email address. Please follow the link to log in to your account."
    failure:
      user:
        magic_link_invalid: "Invalid or expired USER login link."
      admin:
        magic_link_invalid: "Invalid or expired ADMIN login link."
    mailer:
      magic_link:
        user_subject: "Here's your USER magic login link ✨"
        admin_subject: "Here's your ADMIN magic login link ✨"
```

#### Scoped views

If you have multiple Devise models, some that are passwordless and some that aren't, you will probably want to enable [Devise's `scoped_views` setting](https://henrytabima.github.io/rails-setup/docs/devise/configuring-views) so that the models have different signup and login pages (since some models will need password fields and others won't).

If you need to generate fresh Devise views for your models, you can do so like so:

```
$ rails generate devise:views users
$ rails generate devise:views admins
```

Which will generate the whole set of Devise views under these paths:

```
app/views/users/
app/views/admins/
```

### Notes on other Devise strategies

If using the `:rememberable` strategy for "remember me" functionality, you'll need to add a `remember_token` column to your resource, as by default that strategy assumes you're using a password auth strategy and relies on comparing the password's salt to validate cookies:

```ruby
change_table :users do |t|
  t.string :remember_token, limit: 20
end
```

If using the `:confirmable` strategy, you may want to override the default Devise behavior of requiring a fresh login after email confirmation (e.g. [this](https://stackoverflow.com/a/39010334/215168) or [this](https://stackoverflow.com/a/25865526/215168) approach). Otherwise, users will have to get a fresh login link after confirming their email, which makes little sense if they just confirmed they own the email address.

## Alternatives

Other Ruby libraries that offer passwordless authentication:

* [passwordless](https://github.com/mikker/passwordless)
* [magic-link](https://github.com/dvanderbeek/magic-link)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Devise]: https://github.com/heartcombo/devise
[devise-i18n]: https://github.com/heartcombo/devise#i18n
