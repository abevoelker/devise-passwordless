## 1.0.1 - Sep 18, 2023

### Bugfixes

* Fixed bug where `filter_parameters` check erred on regex keys ([#39] - thanks [@thimo]!)

## 1.0.0 - Sep 15, 2023

### Enhancements

* Tokenization encoding/decoding is now fully customizable
* Tokenizer encoding now supports extra metadata ([#27] - thanks [@fastjames] and [@elucid]!)
* Tokenizer encoding now supports `:expires_at` option ([#19], [#21] - thanks [@joeyparis] / [@JoeyLeadJig] and [@bvsatyaram]!)
* Turbo is now properly supported ([#23], [#33] - thanks [@iainbeeston] and [@til]!)
* Signed GlobalID tokenization supported ([#22])
* Concurrent use of password auth (`:database_authenticatable` strategy) now supported ([#13] - thanks [@fschwahn]!)
* `Devise.paranoid` is now respected with new ambiguous messaging i18n option `:magic_link_sent_paranoid` following ([#36] - thanks [@cbldev]!)
* More thorough integration testing using a dummy Rails app
* Added a Rails engine to solve loading issues and tidy up file structuring
* `Passwordless::SessionsController` now uses gem source instead of needing to be generated from a template
* `MagicLinksController` no longer requires a weird `routes.rb` entry to work
* `MagicLinksController` now uses gem source instead of needing to be generated from a template
* `magic_link_(path|url)` view helpers are now implemented for all resources (cleans up mailer view template)
* Users will be redirected after magic link is sent (customized using `after_magic_link_sent_path_for`)
* A warning will be logged if Rails's `filter_parameters` doesn't filter `:token`s from request logs

### Bugfixes

* Autoloading issues related to `uninitialized constant` (e.g.
  `Devise::Passwordless::Mailer`) should now be fixed


[@bvsatyaram]: https://github.com/bvsatyaram
[@cbldev]: https://github.com/cbldev
[@fastjames]: https://github.com/fastjames
[@fschwahn]: https://github.com/fschwahn
[@elucid]: https://github.com/elucid
[@iainbeeston]: https://github.com/iainbeeston
[@joeyparis]: https://github.com/joeyparis
[@JoeyLeadJig]: https://github.com/JoeyLeadJig
[@thimo]: https://github.com/thimo
[@til]: https://github.com/til

[#13]: https://github.com/abevoelker/devise-passwordless/issues/13
[#19]: https://github.com/abevoelker/devise-passwordless/pull/19
[#21]: https://github.com/abevoelker/devise-passwordless/pull/21
[#22]: https://github.com/abevoelker/devise-passwordless/issues/22
[#23]: https://github.com/abevoelker/devise-passwordless/pull/23
[#27]: https://github.com/abevoelker/devise-passwordless/pull/27
[#33]: https://github.com/abevoelker/devise-passwordless/pull/33
[#36]: https://github.com/abevoelker/devise-passwordless/pull/36
[#39]: https://github.com/abevoelker/devise-passwordless/issues/39
