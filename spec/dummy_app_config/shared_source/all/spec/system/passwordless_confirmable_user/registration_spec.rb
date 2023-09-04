require "rails_helper"

RSpec.describe "PasswordlessConfirmableUser registration", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "handles registration using only email" do
    email = "foo@example.com"
    visit "/passwordless_confirmable_users/sign_up"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Sign up")

    # It creates a user in the database
    fill_in "Email", with: email
    expect { click_button "Sign up" }.to change { PasswordlessConfirmableUser.count }.by(1)

    # It sends a confirmation email
    mail = ActionMailer::Base.deliveries.find {|x|
      x.to.include?(email)
    }
    expect(mail.subject).to eq("Confirmation instructions")
  end
end
