require "rails_helper"

RSpec.describe "PasswordlessUser registration", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "handles registration using only email" do
    email = "foo@example.com"

    visit "/passwordless_users/sign_up"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Sign up")

    # It creates a user in the database
    fill_in "Email", with: email
    expect { click_button "Sign up" }.to change { PasswordlessUser.count }.by(1)

    # No emails are sent
    expect(ActionMailer::Base.deliveries).to be_empty

    # It immediately signs them in
    expect(page).to have_css("h2", text: "Sign-in status")
    expect(page).to have_css("p.passwordless_user span.email", text: email)
    expect(page).to have_text("Welcome! You have signed up successfully.")
  end
end
