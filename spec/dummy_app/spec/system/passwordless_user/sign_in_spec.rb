require "rails_helper"

RSpec.describe "PasswordlessUser sign in", :type => :system do
  before do
    driven_by(:rack_test)
  end

  context "an existing user" do
    before do
      @user = PasswordlessUser.create(email: "foo@example.com")
      ActionMailer::Base.deliveries.clear
    end

    it "handles sign in using only email" do
      visit "/passwordless_users/sign_in"
  
      expect(page.status_code).to be(200)
      expect(page).to have_css("h2", text: "Log in")
  
      fill_in "Email", with: "foo@example.com"
      click_button "Log in"
  
      # It sends a magic link email
      email = ActionMailer::Base.deliveries.find {|x|
        x.to.include?("foo@example.com")
      }
      expect(email.subject).to eq("Here's your magic login link ✨")
    end
  end

  it "displays error message if user email not in system" do
    visit "/passwordless_users/sign_in"
  
    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Log in")

    fill_in "Email", with: "foo@example.com"
    click_button "Log in"

    expect(page).to have_css("h2", text: "Log in")
    expect(page).to have_css("p.alert", text: "Could not find a user for that email address")
  end
end
