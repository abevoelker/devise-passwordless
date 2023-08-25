# frozen_string_literal: true
require "devise/mailer"

module Devise::Passwordless
  class Mailer < Devise::Mailer
    def magic_link(record, token, remember_me, opts = {})
      @token = token
      @remember_me = remember_me
      @opts = opts
      devise_mail(record, :magic_link, opts)
    end
  end
end
