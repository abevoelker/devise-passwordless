require "rails_helper"

RSpec.describe "PasswordlessUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  before do
    driven_by(:rack_test)
  end

  it "displays error message if user's email not in system" do
    visit "/passwordless_users/sign_in"
  
    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Log in")

    fill_in "Email", with: email
    click_button "Log in"

    expect(page).to have_css("h2", text: "Log in")
    expect(page).to have_css("p.alert", text: "Could not find a user for that email address")
  end

  context "an existing user" do
    let!(:user) { PasswordlessUser.create(email: email) }

    it "sends magic link and successfully logs in when visiting magic link" do
      visit "/passwordless_users/sign_in"
  
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
      expect(page).to have_css("p.passwordless_user span.email", text: user.email)
    end
  end
end
