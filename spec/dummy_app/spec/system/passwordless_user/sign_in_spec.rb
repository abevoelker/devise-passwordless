require "rails_helper"
require "yaml"

RSpec.describe "PasswordlessUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  before do
    driven_by(:rack_test)
  end

  context "non-existent user" do
    it "displays error message if user's email not in system" do
      visit "/passwordless_users/sign_in"

      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")

      fill_in "Email", with: email
      click_button "Log in"

      expect(page).to have_css("h2", text: "Log in")
      expect(page).to have_css("p.alert", text: "Could not find a user for that email address")
    end

    context "custom i18n" do
      before do
        I18n.backend.store_translations(:en, YAML.load(
          <<~DEVISE_I18N
          devise:
            passwordless:
              not_found_in_database: "Custom not found in database message"
          DEVISE_I18N
        ))
      end

      after do
        I18n.backend.reload!
      end

      it "displays custom not found error message" do
        visit "/passwordless_users/sign_in"

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: email
        click_button "Log in"

        expect(page).to have_css("h2", text: "Log in")
        expect(page).to have_css("p.alert", text: "Custom not found in database message")
      end
    end
  end

  context "an existing user" do
    let!(:user) { PasswordlessUser.create(email: email) }

    it "sends magic link and successfully logs in when visiting magic link" do
      visit "/passwordless_users/sign_in"

      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")

      fill_in "Email", with: user.email
      click_button "Log in"

      # It displays a success message
      expect(page).to have_text("A login link has been sent to your email address. Please follow the link to log in to your account.")

      # It sends a magic link email
      mail = ActionMailer::Base.deliveries.find {|x|
        x.to.include?(email)
      }
      expect(mail.subject).to eq("Here's your magic login link ✨")

      # Log in by visiting magic link
      html = Nokogiri::HTML(mail.body.decoded)
      magic_link = html.css("a")[0].values[0]
      visit magic_link

      # It successfully logs in
      expect(page).to have_css("h2", text: "Sign-in status")
      expect(page).to have_css("p.passwordless_user span.email", text: user.email)
    end

    context "custom i18n" do
      after do
        I18n.backend.reload!
      end

      context "using global i18n options" do
        before do
          I18n.backend.store_translations(:en, YAML.load(
            <<~DEVISE_I18N
            devise:
              passwordless:
                magic_link_sent: "Custom magic link sent message"
              mailer:
                magic_link:
                  subject: "Custom magic link message"
            DEVISE_I18N
          ))
        end

        it "uses the correct i18n messages" do
          visit "/passwordless_users/sign_in"

          expect(page.status_code).to be(200)
          expect(page).to have_css("h2", text: "Log in")

          fill_in "Email", with: user.email
          click_button "Log in"

          # It displays a success message
          expect(page).to have_text("Custom magic link sent message")

          # It sends a magic link email
          mail = ActionMailer::Base.deliveries.find {|x|
            x.to.include?(email)
          }
          expect(mail.subject).to eq("Custom magic link message")
        end
      end

      context "using resource-specific i18n options" do
        before do
          I18n.backend.store_translations(:en, YAML.load(
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
          ))
        end

        it "uses the correct i18n messages" do
          visit "/passwordless_users/sign_in"

          expect(page.status_code).to be(200)
          expect(page).to have_css("h2", text: "Log in")

          fill_in "Email", with: user.email
          click_button "Log in"

          # It displays a success message
          expect(page).to have_text("Custom magic link sent message")

          # It sends a magic link email
          mail = ActionMailer::Base.deliveries.find {|x|
            x.to.include?(email)
          }
          expect(mail.subject).to eq("Custom magic link message")
        end
      end

    end
  end
end
