require "spec_helper"
require "action_controller/railtie"

unless defined?(ApplicationController)
  class ApplicationController < ActionController::Base; end
end

unless defined?(DeviseHelper)
  module DeviseHelper; end
end

devise_path = Gem::Specification.find_by_name("devise").full_gem_path
require "#{devise_path}/app/controllers/devise_controller"
require "#{devise_path}/app/controllers/devise/sessions_controller"
require_relative "../../../app/controllers/devise/passwordless/sessions_controller"

RSpec.describe Devise::Passwordless::SessionsController do
  describe "#create" do
    subject(:create_session) { controller.create }

    let(:controller) { described_class.new }
    let(:resource_class) { double("resource_class") }
    let(:resource) { double("resource") }
    let(:create_params) { {email: "user@example.com", remember_me: "1"} }

    before do
      allow(Devise).to receive(:paranoid).and_return(false)
      allow(controller).to receive(:resource_name).and_return(:user)
      allow(controller).to receive(:resource_class).and_return(resource_class)
      allow(controller).to receive(:create_params).and_return(create_params)
      allow(controller).to receive(:set_flash_message!)
      allow(controller).to receive(:send_magic_link)
      allow(controller).to receive(:after_magic_link_sent_path_for).and_return("/")
      allow(controller).to receive(:devise_redirect_status).and_return(:found)
      allow(controller).to receive(:redirect_to)
    end

    it "finds the resource using the magic link authentication hook" do
      expect(resource_class).to receive(:find_for_magic_link_authentication).with(email: "user@example.com").and_return(resource)
      expect(resource_class).not_to receive(:find_for_authentication)
      expect(controller).to receive(:send_magic_link).with(resource)

      create_session
    end
  end
end
