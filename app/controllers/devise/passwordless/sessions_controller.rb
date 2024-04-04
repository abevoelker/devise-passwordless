class Devise::Passwordless::SessionsController < Devise::SessionsController
  def create
    if (self.resource = resource_class.find_for_authentication(email: create_params[:email]))
      resource.send_magic_link(remember_me: create_params[:remember_me])
      if Devise.paranoid
        set_flash_message!(:notice, :magic_link_sent_paranoid)
      else
        set_flash_message!(:notice, :magic_link_sent)
      end
    else
      self.resource = resource_class.new(create_params)
      if Devise.paranoid
        set_flash_message!(:notice, :magic_link_sent_paranoid)
      else
        set_flash_message!(:alert, :not_found_in_database, now: true)
        render :new, status: devise_error_status
        return
      end
    end

    redirect_to(after_magic_link_sent_path_for(resource), status: devise_redirect_status)
  end

  protected

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
