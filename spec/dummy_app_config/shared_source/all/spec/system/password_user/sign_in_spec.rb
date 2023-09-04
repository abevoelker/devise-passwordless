require "rails_helper"

RSpec.describe "PasswordUser sign in", :type => :system do
  let(:email) { "foo@example.com" }
  let(:password) { "foobar123" }
  before do
    driven_by(:rack_test)
  end

  let!(:user) { PasswordUser.create(email: email, password: password) }

  it "successfully logs in password user using password" do
    visit "/password_users/sign_in"

    expect(page.status_code).to be(200)
    expect(page).to have_css("h2", text: "Log in")

    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Log in"

    # It successfully logs in
    expect(page).to have_css("h2", text: "Sign-in status")
    expect(page).to have_css("p.password_user span.email", text: user.email)
  end
end
