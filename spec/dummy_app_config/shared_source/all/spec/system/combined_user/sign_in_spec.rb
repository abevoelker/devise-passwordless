require "rails_helper"
require "system/shared/shared_passwordless_sign_in_examples"

RSpec.describe "CombinedUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  let(:password) { "foobar123" }
  before do
    driven_by(:rack_test)
  end

  context "signing in with password" do
    let(:sign_in_path) { "/combined_users/sign_in" }
    let!(:user) { CombinedUser.create(email: email, password: password) }

    it "successfully logs in combined user using password" do
      visit "/combined_users/sign_in"

      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")

      fill_in "Email", with: user.email
      fill_in "Password", with: password
      click_button "Log in"

      # It successfully logs in
      expect(page).to have_css("h2", text: "Sign-in status")
      expect(page).to have_css("p.combined_user span.email", text: user.email)
    end

    context "with magic-link authentication disabled" do
      before do
        allow_any_instance_of(CombinedUser).to receive(:active_for_magic_link_authentication?).and_return(false)
      end

      it "successfully logs in combined user using password even with magic-link disabled" do
        visit "/combined_users/sign_in"

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: user.email
        fill_in "Password", with: password
        click_button "Log in"

        # It successfully logs in
        expect(page).to have_css("h2", text: "Sign-in status")
        expect(page).to have_css("p.combined_user span.email", text: user.email)
      end
    end


    context "with password authentication disabled" do
      before do
        expect_any_instance_of(CombinedUser).to receive(:active_for_authentication?).and_return(false)
        expect_any_instance_of(CombinedUser).to receive(:inactive_message).and_return(:password_login_disabled)

        I18n.backend.store_translations(:en, YAML.load(
          <<~DEVISE_I18N
          devise:
            failure:
              password_login_disabled: "Password logins have been disabled. Use magic links instead."
          DEVISE_I18N
        ))
      end

      after do
        I18n.backend.reload!
      end

      it "fails password sign-in with custom error message" do
        visit sign_in_path

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: user.email
        fill_in "Password", with: password
        click_button "Log in"

        # Sign in fails with custom error message
        expect(page).to have_css("h2", text: "Log in")
        expect(page).to have_css("p.alert", text: "Password logins have been disabled. Use magic links instead.")
      end
    end
  end

  context "signing in passwordlessly (with magic links)" do
    let(:sign_in_path) { "/passwordless/combined_users/sign_in" }
    let(:user) { CombinedUser.create(email: email, password: password) }

    context "shared passwordless sign-in examples" do
      let(:css_class) { "combined_user" }
      let(:yaml_global) { YAML.load(
        <<~DEVISE_I18N
        devise:
          passwordless:
            magic_link_sent: "Custom magic link sent message"
            magic_link_sent_paranoid: "Custom paranoid message"
            not_found_in_database: "Custom not found in database message"
          mailer:
            magic_link:
              subject: "Custom magic link message"
        DEVISE_I18N
      )}
      let(:yaml_scoped) { YAML.load(
        <<~DEVISE_I18N
        devise:
          passwordless:
            passwordless_combined_user:
              magic_link_sent: "Custom magic link sent message"
              magic_link_sent_paranoid: "Custom paranoid message"
              not_found_in_database: "Custom not found in database message"
            passwordless_confirmable_user:
              magic_link_sent: "YYY"
            magic_link_sent: "XXX"
          mailer:
            magic_link:
              combined_user_subject: "Custom magic link message"
              passwordless_confirmable_user_subject: "YYY"
              subject: "XXX"
        DEVISE_I18N
      )}

      include_examples "passwordless resource shared sign-in examples"
    end

    context "with passwordless login (magic link authentication) disabled" do
      before do
        expect_any_instance_of(CombinedUser).to receive(:active_for_magic_link_authentication?).and_return(false)
      end

      context "default error message" do
        it "sends magic link, but visiting magic link fails sign-in with default error message" do
          visit sign_in_path

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

          # Sign in fails with custom error message
          expect(page).to have_css("h2", text: "Log in")
          expect(page).to have_css("p.alert", text: "Invalid or expired login link.")
        end
      end

      context "custom error message" do
        before do
          expect_any_instance_of(CombinedUser).to receive(:magic_link_inactive_message).and_return(:passwordless_login_disabled)
        end

        after do
          I18n.backend.reload!
        end

        context "custom unscoped error message" do
          before do
            I18n.backend.store_translations(:en, YAML.load(
              <<~DEVISE_I18N
              devise:
                failure:
                  passwordless_login_disabled: "Passwordless / magic link logins have been disabled. Use your password instead."
              DEVISE_I18N
            ))
          end

          it "sends magic link, but visiting magic link fails sign-in with custom error message" do
            visit sign_in_path

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

            # Sign in fails with custom error message
            expect(page).to have_css("h2", text: "Log in")
            expect(page).to have_css("p.alert", text: "Passwordless / magic link logins have been disabled. Use your password instead.")
          end
        end

        context "custom scoped error message" do
          before do
            I18n.backend.store_translations(:en, YAML.load(
              <<~DEVISE_I18N
              devise:
                failure:
                  combined_user:
                    passwordless_login_disabled: "Passwordless / magic link logins have been disabled. Use your password instead."
              DEVISE_I18N
            ))
          end

          it "sends magic link, but visiting magic link fails sign-in with custom error message" do
            visit sign_in_path

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

            # Sign in fails with custom error message
            expect(page).to have_css("h2", text: "Log in")
            expect(page).to have_css("p.alert", text: "Passwordless / magic link logins have been disabled. Use your password instead.")
          end
        end
      end
    end
  end
end
