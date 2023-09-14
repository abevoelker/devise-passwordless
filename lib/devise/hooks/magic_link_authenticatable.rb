# frozen_string_literal: true

# Deny user access when magic link authentication is disabled
Warden::Manager.after_set_user do |record, warden, options|
  if record && record.respond_to?(:active_for_magic_link_authentication?) && !record.active_for_magic_link_authentication?
    scope = options[:scope]
    warden.logout(scope)
    throw :warden, scope: scope, message: record.magic_link_inactive_message
  end
end
