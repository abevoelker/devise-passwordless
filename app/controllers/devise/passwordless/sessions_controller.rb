class Devise::Passwordless::SessionsController < Devise::SessionsController
  def create
    if (self.resource = resource_class.find_by(email: create_params[:email]))
      resource.send_magic_link(remember_me: create_params[:remember_me])
      set_flash_message!(:notice, :magic_link_sent)
    else
      set_flash_message!(:notice, :not_found_in_database)
    end

    redirect_to(after_magic_link_sent_path_for(resource_class), status: devise_redirect_status)
  end

  protected

  # The path to redirect to after a magic link was sent.
  def after_magic_link_sent_path_for(resource_or_scope)
    stored_location = stored_location_for(resource_or_scope)
    return stored_location if stored_location

    scope = Devise::Mapping.find_scope!(resource_or_scope)
    router_name = Devise.mappings[scope].router_name
    context = router_name ? send(router_name) : self
    context.respond_to?(:root_path) ? context.root_path : "/"
  end

  def translation_scope
    if action_name == "create"
      "devise.passwordless"
    else
      super
    end
  end

  private

  def create_params
    resource_params.permit(:email, :remember_me)
  end

  # Devise < 4.9 fallback support
  # See: https://github.com/heartcombo/devise/wiki/How-To:-Upgrade-to-Devise-4.9.0-%5BHotwire-Turbo-integration%5D
  def devise_redirect_status
    Devise.try(:responder).try(:redirect_status) || :found
  end

  def devise_error_status
    Devise.try(:responder).try(:error_status) || :ok
  end
end
