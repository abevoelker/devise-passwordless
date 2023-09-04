class CustomSessionsController < Devise::Passwordless::SessionsController
  def create
    redirect_to test_custom_controllers_foo_path
  end
end
