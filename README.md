# Devise::Passwordless

A passwordless login strategy for [Devise] using emailed magic links

## Features

* No passwords - users receive magic link emails to register / sign-in
* No database changes needed - magic links are stateless tokens
* [Choose your token encoding algorithm or easily write your own](#tokenizers)
* [Can be combined with traditional password authentication in the same model](#combining-password-and-passwordless-auth-in-the-same-model)
* [Supports multiple user (resource) types](#multiple-user-resource-types)
* All the goodness of Devise!

## 0.x to 1.0 Upgrade

⭐ The 1.0 release includes significant breaking changes! ⭐

If you're upgrading from 0.x to 1.0, read [the upgrade guide][] for
a list of changes you'll need to make.

[the upgrade guide]: https://github.com/abevoelker/devise-passwordless/blob/master/UPGRADING.md

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

This gem adds a `:magic_link_authenticatable` strategy that can be used in your Devise models for passwordless authentication. This strategy plays well with most other Devise strategies (see [*compatibility with other Devise strategies*](#compatibility-with-other-devise-strategies)).

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

Finally, we need to update Devise's views to remove references to passwords. We will assume you're using the standard Devise views for all your registrations and logins; if you need to support multiple Devise models, some with passwordless login and some with password login, then jump down to the [multiple users section below](#multiple-user-resource-types).

First, ensure you have Devise views generated for your project under `app/views/devise`. If not, you can generate them with:

```
rails generate devise:views
```

Then, delete these files and directories:

```
rm -rf app/views/devise/passwords
rm -f app/views/devise/mailer/password_change.html.erb
rm -f app/views/devise/mailer/reset_password_instructions.html.erb
```

Then, edit these files to remove password references:

* app/views/devise/registrations/new.html.erb
  * Delete fields `:password` and `:password_confirmation`
* app/views/devise/registrations/edit.html.erb
  * Delete fields `:password`, `:password_confirmation`, `:current_password`
* app/views/devise/sessions/new.html.erb
  * Delete field `:password`

That's it! 🎉 Now check out the customization section so that you
may change the default configuration to better match your needs.

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

# When using the :trackable module and MessageEncryptorTokenizer, set to true to 
# consider magic link tokens generated before the user's current sign in time to 
# be expired. In other words, each time you sign in, all existing magic links 
# will be considered invalid.
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
      magic_link_sent_paranoid: "If your account exists, you will receive an email with a login link. Please follow the link to log in to your account."
    failure:
      magic_link_invalid: "Invalid or expired login link."
    mailer:
      magic_link:
        subject: "Here's your magic login link ✨"
```

**Note**: If [Devise's paranoid mode][] is enabled in your Devise initializer, the
`:magic_link_sent_paranoid` message will be used both when a user account exists
and when it does not exist to prevent account enumeration vulnerabilities. If
paranoid mode is disabled, then `:magic_link_sent` will be used for existing
accounts, and `:not_found_in_database` when no account was found.

[Devise's paranoid mode]: https://github.com/heartcombo/devise/wiki/How-To:-Using-paranoid-mode,-avoid-user-enumeration-on-registerable

To customize the magic link email body, edit `app/views/devise/mailer/magic_link.html.erb`

## Manually creating and sending magic links

Magic links are created and sent normally using Devise's views for sign-in and registration, but you can create them manually as well.

To send a magic link email, do this:

```ruby
user = User.last
user.send_magic_link
# additional options are passed through to Devise's mailer logic
user.send_magic_link(remember_me: true, subject: "Custom email subject", "X-Entity-Ref-ID": SecureRandom.uuid)
```

If you only need to generate the token portion of a magic link, you can do this:

```ruby
# see the tokenizer's #encode method for all supported keyword options
token = user.encode_passwordless_token(expires_at: 2.hours.from_now)
```

Or, to generate the full magic link URL, use this URL view helper:

```ruby
user_magic_link_url(
  user: {
    email: user.email,
    token: token,
    remember_me: true
  }
)
```

## Redirecting after magic link is sent

After a user enters their email on the sign-in page, and a magic link is sent, the user
will be redirected back to the `:root` path of the application.

To provide a custom redirect location, you can write a custom
`after_magic_link_sent_path_for` helper, similar to
[how Devise's `after_sign_in_path_for` helper works][after_sign_in_path_for]:

```ruby
class ApplicationController < ActionController::Base
  def after_magic_link_sent_path_for(resource_or_scope)
    "/foo"
  end
end
```

[after_sign_in_path_for]: https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update

If you need to have different paths for multiple different types of resources,
you can write something like this:

```ruby
class ApplicationController < ActionController::Base
  def after_magic_link_sent_path_for(resource_or_scope)
    case Devise::Mapping.find_scope!(resource_or_scope)
    when :user
      some_path
    when :admin
      some_other_path
    end
  end
end
```

And, if you need more complex behavior, you can always write a custom sessions
controller for each resource:

```ruby
# app/controllers/custom_sessions_controller.rb
class CustomSessionsController < Devise::Passwordless::SessionsController
  def create
    # your custom logic
  end
end

# config/routes.rb
Rails.application.routes.draw do
  devise_for :users,
    controllers: { sessions: "custom_sessions" }
end
```

## Tokenizers

Tokenizers handle encoding and decoding of magic link tokens. There are multiple
pre-built ones to choose from, or [you can write your own](#your-own-custom-tokenizer).

Set the default tokenizer in your Devise initializer (`config.passwordless_tokenizer`),
which will be the global default. If you want a model to have a different tokenizer
than the default, you can define a class method `::passwordless_tokenizer` on your
model and that will be used instead. Models can have different tokenizers from
each other in this way.

### SignedGlobalIDTokenizer

```ruby
config.passwordless_tokenizer = "SignedGlobalIDTokenizer"
```

Tokens are [Rails signed Global IDs][globalid]. This is the default for new installs.

Reasons to use or not use:

* The implementation is short and simple, so less likely to be buggy
* Should work with all ORMs that implement GlobalID support
* Cannot add arbitrary metadata to generated tokens
* Tokens are signed, not encrypted, so some data will be visible when base64-decoded
* Tokens tend to be a little longer (~30 chars IME) than MessageEncryptors'

[globalid]: https://github.com/rails/globalid

### MessageEncryptorTokenizer

```ruby
config.passwordless_tokenizer = "MessageEncryptorTokenizer"
```

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
    [resource_class.order("RANDOM()").limit(1).first, extra_data={}]
  end
end

# config/initializers/devise.rb
config.passwordless_tokenizer = "::LuckyUserTokenizer"
```

## Multiple user (resource) types

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
        magic_link_sent_paranoid: "If your USER account exists, you will receive an email with a login link. Please follow the link to log in to your account."
      admin:
        not_found_in_database: "Could not find an ADMIN for that email address"
        magic_link_sent: "An ADMIN login link has been sent to your email address. Please follow the link to log in to your account."
        magic_link_sent_paranoid: "If your ADMIN account exists, you will receive an email with a login link. Please follow the link to log in to your account."
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

### Scoped views

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

## Combining password and passwordless auth in the same model

It is possible to use both traditional password authentication (i.e. the
`:database_authenticatable` strategy) alongside magic link authentication in
the same model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :magic_link_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
```

How you end up implementing it will be highly dependent on your use case. By
default, all password validations will still run - so on registration, users
will have to provide passwords - but they'll be able to log in via either
password OR magic link (you'll have to customize your routes and views to
make the separate paths accessible).

Here's an example routes file of that scenario (a separate namespace is
needed because the password vs. passwordless paths use different sessions
controllers):

```ruby
devise_for :users
namespace "passwordless" do
  devise_for :users,
    controllers: { sessions: "devise/passwordless/sessions" }
end
```

Visiting `/users/sign_in` will lead to a password sign in, while
`/passwordless/users/sign_in` will lead to the magic link sign in flow
(you'll need to [generate the necessary Devise views](#scoped-views)
to support the different sign-in forms).

### Disabling password authentication or magic link authentication

Rather than *all* your users having access to *both* authentication methods,
it may be the case that you want *some* users to use magic links, *some*
to use passwords, or some combination between the two.

This can be managed by defining some methods that disable the relevant
authentication strategy and determine the failure message. Here are
examples for both:

### Disabling password authentication

Let's say you want to disable password authentication for everyone except
people named Bob:

```ruby
class User < ApplicationRecord
  # devise :database_authenticatable, :magic_link_authenticatable, ...

  def first_name_bob?
    self.first_name.downcase == "bob"
  end

  # The `super` is important in the following two methods as other
  # auth strategies chain onto these methods:

  def active_for_authentication?
    super && first_name_bob?
  end

  def inactive_message
    first_name_bob? ? super : :first_name_not_bob
  end
end
```

Then, you add this to your `devise.yml` to customize the error message:

```yaml
devise:
  failure:
    first_name_not_bob: "Sorry, only Bobs may log in using their password. Try magic link login instead."
```

Now, when users not named Bob try to log in with their password, it'll fail with
your custom failure message.

### Disabling passwordless / magic link authentication

Disabling magic link authentication is a similar process, just with different
method names:

```ruby
class User < ApplicationRecord
  # devise :database_authenticatable, :magic_link_authenticatable, ...

  def first_name_alice?
    self.first_name.downcase == "alice"
  end

  # The `super` is actually not important at the moment for these, but if
  # any future Devise strategies were to extend this one, they will be.

  def active_for_magic_link_authentication?
    super && first_name_alice?
  end

  def magic_link_inactive_message
    first_name_alice? ? super : :first_name_not_alice_magic_link
  end
end
```

```yaml
devise:
  failure:
    first_name_not_alice_magic_link: "Sorry, only Alices may log in using magic links. Try password login instead."
```

## Compatibility with other Devise strategies

If using the `:rememberable` strategy for "remember me" functionality, you'll need to add a `remember_token` column to your resource, as by default that strategy assumes you're using a password auth strategy and relies on comparing the password's salt to validate cookies:

```ruby
change_table :users do |t|
  t.string :remember_token, limit: 20
end
```

If using the `:confirmable` strategy, you may want to override the default Devise behavior of requiring a fresh login after email confirmation (e.g. [this](https://stackoverflow.com/a/39010334/215168) or [this](https://stackoverflow.com/a/25865526/215168) approach). Otherwise, users will have to get a fresh login link after confirming their email, which makes little sense if they just confirmed they own the email address.

## Hotwire/Turbo support

If you're using Hotwire/Turbo, be sure that you're on Devise >= 4.9 and that you're
setting the `config.responder` config value in your Devise initializer to appropriate
values.

See the [Devise 4.9 Turbo upgrade guide][] for more info.

[Devise 4.9 Turbo upgrade guide]: https://github.com/heartcombo/devise/wiki/How-To:-Upgrade-to-Devise-4.9.0-%5BHotwire-Turbo-integration%5D

## ActiveJob support

If you want to use ActiveJob to send magic link emails asynchronously through
a queuing backend, you can accomplish it the same way you
[enable this functionality in any Devise install][devise-activejob]:

```ruby
class User
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
```

[devise-activejob]: https://github.com/heartcombo/devise/blob/main/README.md#activejob-integration

## Rails logs security

Rails's default configuration filters `:token` parameters out of request logs (and
`Devise::Passwordless` will issue a warning if it detects the configuration doesn't). So request
logs shouldn't link magic link tokens.

However, there are some other default Rails logging behaviors that may cause plaintext magic
link tokens to leak into log files:

1. Action Mailer logs the entire contents of all outgoing emails to the DEBUG level. Magic link tokens delivered to users in email will be leaked.
2. Active Job logs all arguments to every enqueued job at the INFO level. If you configure Devise to use `deliver_later` to send passwordless emails, magic link tokens will be leaked.

Rails sets the production logger level to INFO by default. Consider changing your production logger level to WARN if you wish to prevent tokens from being leaked into your logs. In `config/environments/production.rb`:

```ruby
config.log_level = :warn
```

(Partially adapted from the [Devise guide on password reset tokens][], which this section also applies to)

[Devise guide on password reset tokens]: https://github.com/heartcombo/devise/blob/main/README.md#password-reset-tokens-and-rails-logs

## Alternatives

Other Ruby libraries that offer passwordless authentication:

* [passwordless](https://github.com/mikker/passwordless)
* [magic-link](https://github.com/dvanderbeek/magic-link)

## Gem development

### Running tests

To run the set of basic gem tests, do:

```
$ bundle
$ bundle exec rake
```

The more important and more thorough tests utilize a "dummy" Rails application.

To run this full suite of dummy app tests across all supported versions of Ruby and Rails,
you can use [nektos/act][] to run the same tests that run in our GitHub Workflow CI:

```
$ act -W .github/workflows/test.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --no-cache-server
```

To run only against specific versions of Ruby or Rails, you can use the `--matrix` flag of `act`:

```
$ act -W .github/workflows/test.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --no-cache-server --matrix ruby-version:3.2 --matrix rails-version:7 --matrix rails-version:6.1
```

The above example will only run the tests for Rails 7 and Rails 6.1 using Ruby 3.2.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Devise]: https://github.com/heartcombo/devise
[devise-i18n]: https://github.com/heartcombo/devise#i18n
[nektos/act]: https://github.com/nektos/act
