class CustomMagicLinksController < Devise::MagicLinksController
  def show
    redirect_to test_custom_controllers_bar_path
  end
end
