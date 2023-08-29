require "rails_helper"

RSpec.describe "PasswordlessUser sign in", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "displays error message if user's email not in system" do
    visit "/passwordless_users/sign_in"
  
    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Log in")

    fill_in "Email", with: "foo@example.com"
    click_button "Log in"

    expect(page).to have_css("h2", text: "Log in")
    expect(page).to have_css("p.alert", text: "Could not find a user for that email address")
  end

  context "an unconfirmed user" do
    let!(:user) { PasswordlessUser.new(email: "foo@example.com").tap{|x|
      x.skip_confirmation_notification!
      x.save!
    }}

    it "sends magic link, but fails log in when visiting magic link" do
      visit "/passwordless_users/sign_in"
  
      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")
  
      fill_in "Email", with: user.email
      click_button "Log in"
  
      # It sends a magic link email
      email = ActionMailer::Base.deliveries.find {|x|
        x.to.include?("foo@example.com")
      }
      expect(email.subject).to eq("Here's your magic login link ✨")

      # Log in by visiting magic link
      html = Nokogiri::HTML(email.body.decoded)
      magic_link = html.css("a")[0].values[0]
      visit magic_link

      # It fails login due to unconfirmed email
      expect(page).to have_css("h2", text: "Log in")
      expect(page).to have_text("You have to confirm your email address before continuing.")

      # It shows the user as not signed in
      visit root_path
      expect(page).to have_css("p.passwordless_user", text: "(not signed in)")
    end
  end

  context "a confirmed user" do
    let!(:user) { PasswordlessUser.new(email: "foo@example.com").tap{|x|
      x.skip_confirmation!
      x.skip_confirmation_notification!
      x.save!
    }}

    it "sends magic link and successfully logs in when visiting magic link" do
      visit "/passwordless_users/sign_in"
  
      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")
  
      fill_in "Email", with: user.email
      click_button "Log in"
  
      # It sends a magic link email
      email = ActionMailer::Base.deliveries.find {|x|
        x.to.include?("foo@example.com")
      }
      expect(email.subject).to eq("Here's your magic login link ✨")

      # Log in by visiting magic link
      html = Nokogiri::HTML(email.body.decoded)
      magic_link = html.css("a")[0].values[0]
      visit magic_link

      # It successfully logs in
      expect(page).to have_css("h2", text: "Sign-in status")
      expect(page).to have_css("p.passwordless_user span.email", text: user.email)
    end
  end
end
