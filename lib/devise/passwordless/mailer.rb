if defined?(Devise::Mailer)
  Devise::Mailer.class_eval do
    def passwordless_link(record, remember_me, opts = {})
      @remember_me = remember_me
      @token = Devise::Passwordless::LoginToken.encode(record)
      devise_mail(record, :passwordless_link, opts)
    end
  end
end
