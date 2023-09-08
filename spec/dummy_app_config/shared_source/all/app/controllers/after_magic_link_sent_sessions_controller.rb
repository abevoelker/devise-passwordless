class AfterMagicLinkSentSessionsController < Devise::Passwordless::SessionsController
  def after_magic_link_sent_path_for(*args)
    test_custom_after_magic_link_sent_redirect_baz_path
  end
end
