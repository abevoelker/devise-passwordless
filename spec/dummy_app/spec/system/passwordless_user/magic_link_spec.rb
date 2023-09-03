require "rails_helper"

RSpec.describe "PasswordlessUser magic links", :type => :system do
  let(:email) { "foo@example.com" }
  let(:css_class) { "passwordless_user" }

  before do
    driven_by(:rack_test)
  end

  let(:user) { PasswordlessUser.create(email: email) }
  let(:token) { user.encode_passwordless_token }

  it "successfully logs in using magic link" do
    visit send("#{user.model_name.param_key}_magic_link_path", user.model_name.param_key => {email: user.email, token: token, remember_me: false})

    # It successfully logs in
    expect(page).to have_css("h2", text: "Sign-in status")
    expect(page).to have_css("p.#{css_class} span.email", text: user.email)
  end
end
