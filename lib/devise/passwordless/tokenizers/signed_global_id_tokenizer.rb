require "globalid"

module Devise::Passwordless
  class SignedGlobalIDTokenizer
    def self.encode(resource, expires_in: nil)
      resource.to_sgid(expires_in: expires_in || resource.class.passwordless_login_within, for: "login").to_s
    end

    def self.decode(token, resource_class)
      resource = GlobalID::Locator.locate_signed(token, for: "login")
      raise ExpiredTokenError unless resource
      raise InvalidTokenError if resource.class != resource_class
      [resource, {}]
    end
  end
end
