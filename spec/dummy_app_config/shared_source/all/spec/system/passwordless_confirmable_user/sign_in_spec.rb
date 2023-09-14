require "rails_helper"
require "yaml"
require "system/shared/shared_passwordless_sign_in_examples"

RSpec.describe "PasswordlessConfirmableUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  before do
    driven_by(:rack_test)
  end

  let(:unconfirmed_user) { PasswordlessConfirmableUser.new(email: email).tap{|x|
    x.skip_confirmation_notification!
    x.save!
  }}
  let(:confirmed_user) { PasswordlessConfirmableUser.new(email: email).tap{|x|
    x.skip_confirmation!
    x.skip_confirmation_notification!
    x.save!
  }}

  let(:sign_in_path) { "/passwordless_confirmable_users/sign_in" }
  let(:css_class) { "passwordless_confirmable_user" }

  context "a confirmed user" do
    let(:user) { confirmed_user }
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
            magic_link_sent: "YYY"
          passwordless_confirmable_user:
            magic_link_sent: "Custom magic link sent message"
          magic_link_sent: "XXX"
        mailer:
          magic_link:
            passwordless_user_subject: "YYY"
            passwordless_confirmable_user_subject: "Custom magic link message"
            subject: "XXX"
      DEVISE_I18N
    )}

    include_examples "passwordless resource shared sign-in examples"
  end

  context "an unconfirmed user" do
    let!(:user) { unconfirmed_user } # force eager evaluation (create user)

    it "sends magic link, but fails log in when visiting magic link" do
      visit sign_in_path
  
      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")
  
      fill_in "Email", with: user.email
      click_button "Log in"
  
      # It sends a magic link email
      mail = ActionMailer::Base.deliveries.find {|x|
        x.to.include?(email)
      }
      expect(mail.subject).to eq("Here's your magic login link ✨")

      # Log in by visiting magic link
      html = Nokogiri::HTML(mail.body.decoded)
      magic_link = html.css("a")[0].values[0]
      visit magic_link

      # It fails login due to unconfirmed email
      expect(page).to have_css("h2", text: "Log in")
      expect(page).to have_text("You have to confirm your email address before continuing.")

      # It shows the user as not signed in
      visit root_path
      expect(page).to have_css("p.#{css_class}", text: "(not signed in)")
    end
  end
end
