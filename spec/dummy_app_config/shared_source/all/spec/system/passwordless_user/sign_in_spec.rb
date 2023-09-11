require "rails_helper"
require "yaml"
require "system/shared/shared_sign_in_spec"

RSpec.describe "PasswordlessUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  before do
    driven_by(:rack_test)
  end

  context "shared examples" do
    let(:sign_in_path) { "/passwordless_users/sign_in" }
    let(:user) { PasswordlessUser.create(email: email) }
    let(:css_class) { "passwordless_user" }
    let(:yaml_global) { YAML.load(
      <<~DEVISE_I18N
      devise:
        passwordless:
          magic_link_sent: "Custom magic link sent message"
        mailer:
          magic_link:
            subject: "Custom magic link message"
      DEVISE_I18N
    )}
    let(:yaml_specific) { YAML.load(
      <<~DEVISE_I18N
      devise:
        passwordless:
          passwordless_user:
            magic_link_sent: "Custom magic link sent message"
          passwordless_confirmable_user:
            magic_link_sent: "YYY"
          magic_link_sent: "XXX"
        mailer:
          magic_link:
            passwordless_user_subject: "Custom magic link message"
            passwordless_confirmable_user_subject: "YYY"
            subject: "XXX"
      DEVISE_I18N
    )}

    include_examples "resource sign-in shared examples"
  end

  context "custom sessions controller" do
    let(:sign_in_path) { "/test_custom_controllers/passwordless_users/sign_in" }
    let!(:user) { PasswordlessUser.create(email: email) }

    it "uses a custom sessions controller" do
      visit sign_in_path

      fill_in "Email", with: email
      click_button "Log in"

      expect(current_path).to eq("/test_custom_controllers/foo")
      expect(page.body).to eq("foo")
    end
  end

  context "custom magic links controller" do
    let(:magic_link_path) { "/test_custom_controllers/passwordless_users/magic_link" }

    it "uses a custom magic links controller" do
      visit magic_link_path

      expect(current_path).to eq("/test_custom_controllers/bar")
      expect(page.body).to eq("bar")
    end
  end

  context "customizing after_magic_link_sent_path_for" do
    let(:sign_in_path) { "/passwordless_users/sign_in" }
    let!(:user) { PasswordlessUser.create(email: email) }

    context "defining a after_magic_link_sent_path_for helper on ApplicationController" do
      before do
        expect_any_instance_of(ApplicationController).to receive(:after_magic_link_sent_path_for).and_return("/custom_after_magic_link_sent")
      end

      it "uses the after_magic_link_sent_path_for" do
        visit sign_in_path

        fill_in "Email", with: email
        click_button "Log in"

        expect(current_path).to eq("/custom_after_magic_link_sent")
        expect(page.body).to eq("custom_after_magic_link_sent")
      end
    end

    context "defining a after_magic_link_sent_path_for helper on the SessionsController" do
      let(:sign_in_path) { "/test_custom_after_magic_link_sent_redirect/passwordless_users/sign_in" }

      it "uses the after_magic_link_sent_path_for" do
        visit sign_in_path

        fill_in "Email", with: email
        click_button "Log in"

        expect(current_path).to eq("/test_custom_after_magic_link_sent_redirect/baz")
        expect(page.body).to eq("baz")
      end
    end
  end
end
