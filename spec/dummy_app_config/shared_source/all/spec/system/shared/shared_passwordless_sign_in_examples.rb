RSpec.shared_examples "passwordless resource shared sign-in examples" do
  context "paranoid mode enabled (default)" do
    let(:login_message) { "If your account exists, you will receive an email with a login link. Please follow the link to log in to your account." }

    before do
      allow(Devise).to receive(:paranoid).and_return(true)
    end

    context "non-existent user" do
      it "displays an ambiguous message if user's email not in system" do
        visit sign_in_path

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: email
        click_button "Log in"

        expect(page).to have_css("h2", text: "Sign-in status")
        expect(page).to have_css("p.notice", text: login_message)
      end

      context "custom i18n" do
        let(:expected_message) { "Custom paranoid message" }

        after do
          I18n.backend.reload!
        end

        context "using global i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_global)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: email
            click_button "Log in"

            expect(page).to have_css("h2", text: "Sign-in status")
            expect(page).to have_css("p.notice", text: expected_message)
          end
        end

        context "using scoped i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_scoped)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: email
            click_button "Log in"

            expect(page).to have_css("h2", text: "Sign-in status")
            expect(page).to have_css("p.notice", text: expected_message)
          end
        end
      end
    end

    context "an existing user" do
      before { user } # force eager evaluation (create user)
      let(:magic_link_message) { "Here's your magic login link ✨" }

      it "sends magic link and successfully logs in when visiting magic link" do
        visit sign_in_path

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: user.email
        click_button "Log in"

        # It displays a success message
        expect(page).to have_text(login_message)

        # It sends a magic link email
        mail = ActionMailer::Base.deliveries.find {|x|
          x.to.include?(email)
        }
        expect(mail.subject).to eq(magic_link_message)

        # Log in by visiting magic link
        html = Nokogiri::HTML(mail.body.decoded)
        magic_link = html.css("a")[0].values[0]
        visit magic_link

        # It successfully logs in
        expect(page).to have_css("h2", text: "Sign-in status")
        expect(page).to have_css("p.#{css_class} span.email", text: user.email)
      end

      context "custom i18n" do
        let(:login_message) { "Custom paranoid message" }
        let(:magic_link_message) { "Custom magic link message" }

        after do
          I18n.backend.reload!
        end

        context "using global i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_global)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: user.email
            click_button "Log in"

            # It displays a success message
            expect(page).to have_text(login_message)

            # It sends a magic link email
            mail = ActionMailer::Base.deliveries.find {|x|
              x.to.include?(email)
            }
            expect(mail.subject).to eq(magic_link_message)
          end
        end

        context "using scoped i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_scoped)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: user.email
            click_button "Log in"

            # It displays a success message
            expect(page).to have_text(login_message)

            # It sends a magic link email
            mail = ActionMailer::Base.deliveries.find {|x|
              x.to.include?(email)
            }
            expect(mail.subject).to eq(magic_link_message)
          end
        end
      end
    end
  end

  context "paranoid mode disabled" do
    before do
      allow(Devise).to receive(:paranoid).and_return(false)
    end

    context "non-existent user" do
      let(:login_message) { "Could not find a user for that email address" }

      it "displays error message if user's email not in system" do
        visit sign_in_path

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: email
        click_button "Log in"

        expect(page).to have_css("h2", text: "Log in")
        expect(page).to have_css("p.alert", text: login_message)
      end

      context "custom i18n" do
        let(:expected_message) { "Custom not found in database message" }

        after do
          I18n.backend.reload!
        end

        context "using global i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_global)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: email
            click_button "Log in"

            expect(page).to have_css("h2", text: "Log in")
            expect(page).to have_css("p.alert", text: expected_message)
          end
        end

        context "using scoped i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_scoped)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: email
            click_button "Log in"

            expect(page).to have_css("h2", text: "Log in")
            expect(page).to have_css("p.alert", text: expected_message)
          end
        end
      end
    end

    context "an existing user" do
      before { user } # force eager evaluation (create user)
      let(:login_message) { "A login link has been sent to your email address. Please follow the link to log in to your account." }
      let(:magic_link_message) { "Here's your magic login link ✨" }

      it "sends magic link and successfully logs in when visiting magic link" do
        visit sign_in_path

        expect(page.status_code).to be(200)
        expect(page).to have_css("h2", text: "Log in")

        fill_in "Email", with: user.email
        click_button "Log in"

        # It displays a success message
        expect(page).to have_text(login_message)

        # It sends a magic link email
        mail = ActionMailer::Base.deliveries.find {|x|
          x.to.include?(email)
        }
        expect(mail.subject).to eq(magic_link_message)

        # Log in by visiting magic link
        html = Nokogiri::HTML(mail.body.decoded)
        magic_link = html.css("a")[0].values[0]
        visit magic_link

        # It successfully logs in
        expect(page).to have_css("h2", text: "Sign-in status")
        expect(page).to have_css("p.#{css_class} span.email", text: user.email)
      end

      context "custom i18n" do
        let(:login_message) { "Custom magic link sent message" }
        let(:magic_link_message) { "Custom magic link message" }

        after do
          I18n.backend.reload!
        end

        context "using global i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_global)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: user.email
            click_button "Log in"

            # It displays a success message
            expect(page).to have_text(login_message)

            # It sends a magic link email
            mail = ActionMailer::Base.deliveries.find {|x|
              x.to.include?(email)
            }
            expect(mail.subject).to eq(magic_link_message)
          end
        end

        context "using scoped i18n options" do
          before do
            I18n.backend.store_translations(:en, yaml_scoped)
          end

          it "uses the correct i18n messages" do
            visit sign_in_path

            expect(page.status_code).to be(200)
            expect(page).to have_css("h2", text: "Log in")

            fill_in "Email", with: user.email
            click_button "Log in"

            # It displays a success message
            expect(page).to have_text(login_message)

            # It sends a magic link email
            mail = ActionMailer::Base.deliveries.find {|x|
              x.to.include?(email)
            }
            expect(mail.subject).to eq(magic_link_message)
          end
        end
      end
    end
  end
end
