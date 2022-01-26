require "rails_helper"

RSpec.describe "App startup", :type => :system do
  before do
    driven_by(:rack_test)
  end

  it "has a homepage" do
    visit "/"

    expect(page.status_code).to be(200)
  end
end
