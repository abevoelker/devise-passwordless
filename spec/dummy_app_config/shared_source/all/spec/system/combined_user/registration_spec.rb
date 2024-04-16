require "rails_helper"

RSpec.describe "CombinedUser registration", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "handles registration email and password" do
    email = "foo@example.com"
    password = "foobar123"

    visit "/combined_users/sign_up"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Sign up")

    # It creates a user in the database
    fill_in "Email", with: email
    fill_in "Password", with: password
    fill_in "Password confirmation", with: password
    expect { click_button "Sign up" }.to change { CombinedUser.count }.by(1)

    # No emails are sent
    expect(ActionMailer::Base.deliveries).to be_empty

    # It immediately signs them in
    expect(page).to have_css("h2", text: "Sign-in status")
    expect(page).to have_css("p.combined_user span.email", text: email)
    expect(page).to have_text("Welcome! You have signed up successfully.")
  end

  it "validates password" do
    email = "foo@example.com"

    visit "/combined_users/sign_up"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Sign up")

    # It creates a user in the database
    fill_in "Email", with: email
    expect { click_button "Sign up" }.not_to change { CombinedUser.count }

    # No emails are sent
    expect(ActionMailer::Base.deliveries).to be_empty

    # Sign in fails with custom error message
    expect(page).to have_css("h2", text: "Sign up")
    expect(page).to have_css("#error_explanation", text: "1 error prohibited this combined user from being saved:\nPassword can't be blank")
    expect(page).not_to have_text("Welcome! You have signed up successfully.")
  end
end
