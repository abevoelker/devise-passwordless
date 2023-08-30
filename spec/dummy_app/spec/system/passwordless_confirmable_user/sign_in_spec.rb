require "rails_helper"

RSpec.describe "PasswordlessConfirmableUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  before do
    driven_by(:rack_test)
  end

  it "displays error message if user's email not in system" do
    visit "/passwordless_confirmable_users/sign_in"
  
    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Log in")

    fill_in "Email", with: email
    click_button "Log in"

    expect(page).to have_css("h2", text: "Log in")
    expect(page).to have_css("p.alert", text: "Could not find a user for that email address")
  end

  context "an unconfirmed user" do
    let!(:user) { PasswordlessConfirmableUser.new(email: email).tap{|x|
      x.skip_confirmation_notification!
      x.save!
    }}

    it "sends magic link, but fails log in when visiting magic link" do
      visit "/passwordless_confirmable_users/sign_in"
  
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
      expect(page).to have_css("p.passwordless_confirmable_user", text: "(not signed in)")
    end
  end

  context "a confirmed user" do
    let!(:user) { PasswordlessConfirmableUser.new(email: email).tap{|x|
      x.skip_confirmation!
      x.skip_confirmation_notification!
      x.save!
    }}

    it "sends magic link and successfully logs in when visiting magic link" do
      visit "/passwordless_confirmable_users/sign_in"

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

      # It successfully logs in
      expect(page).to have_css("h2", text: "Sign-in status")
      expect(page).to have_css("p.passwordless_confirmable_user span.email", text: user.email)
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
          visit "/passwordless_confirmable_users/sign_in"

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
          ))
        end

        it "uses the correct i18n messages" do
          visit "/passwordless_confirmable_users/sign_in"

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
