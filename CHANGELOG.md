## 1.0.0

### Enhancements

* Tokenization encoding/decoding is now fully customizable
* More thorough integration testing using a dummy Rails app
* Added a Rails engine to solve loading issues and tidy up file structuring
* `Passwordless::SessionsController` now uses gem source instead of needing to be generated from a template
* `MagicLinksController` no longer requires a weird `routes.rb` entry to work
* `MagicLinksController` now uses gem source instead of needing to be generated from a template
* `magic_link_(path|url)` view helpers are now implemented for all resources (cleans up mailer view template)

### Bugfixes

* Requiring `Devise::Passwordless::Mailer` should no longer cause errors
