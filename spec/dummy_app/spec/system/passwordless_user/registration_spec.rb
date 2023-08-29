require "rails_helper"

RSpec.describe "PasswordlessUser registration", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "handles registration using only email" do
    visit "/passwordless_users/sign_up"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Sign up")

    # It creates a user in the database
    fill_in "Email", with: "foo@example.com"
    expect { click_button "Sign up" }.to change { PasswordlessUser.count }.by(1)

    # It sends a confirmation email
    email = ActionMailer::Base.deliveries.find {|x|
      x.to.include?("foo@example.com")
    }
    expect(email.subject).to eq("Confirmation instructions")
  end
end
