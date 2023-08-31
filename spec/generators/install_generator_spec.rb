require "spec_helper"
require "generator_spec"

RSpec.describe Devise::Passwordless::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __FILE__)
  before do
    prepare_destination
  end

  context "Devise installed" do
    let(:default_devise_initializer) {
      File.expand_path("../templates/default/devise.rb", __FILE__)
    }
    let(:default_devise_yml) {
      File.expand_path("../templates/default/devise.en.yml", __FILE__)
    }

    let(:expected_devise_initializer) {
      File.expand_path("../templates/expected/devise.rb", __FILE__)
    }
    let(:expected_devise_yml) {
      File.expand_path("../templates/expected/devise.en.yml", __FILE__)
    }
    let(:expected_mailer_view) {
      File.expand_path("../templates/expected/magic_link.html.erb", __FILE__)
    }

    before do
      FileUtils.mkdir_p(File.join(destination_root, "config/initializers"))
      FileUtils.mkdir_p(File.join(destination_root, "config/locales"))
      FileUtils.cp(default_devise_initializer, File.join(destination_root, "config/initializers/devise.rb"))
      FileUtils.cp(default_devise_yml, File.join(destination_root, "config/locales/devise.en.yml"))
      run_generator
    end

    it "updates the Devise initializer with passwordless config" do
      expected = File.read(expected_devise_initializer)
      expect(File.read(File.join(destination_root, "config/initializers/devise.rb"))).to eq(expected)
    end

    it "updates the Devise en.yml with passwordless config" do
      expected = File.read(expected_devise_yml)
      expect(File.read(File.join(destination_root, "config/locales/devise.en.yml"))).to eq(expected)
    end

    it "creates the passwordless mailer view" do
      expected = File.read(expected_mailer_view)
      expect(File.read(File.join(destination_root, "app/views/devise/mailer/magic_link.html.erb"))).to eq(expected)
    end

    it "generates the controllers" do
      assert_file "app/controllers/devise/passwordless/sessions_controller.rb", /Devise::Passwordless::SessionsController/
    end
  end

  context "Devise not installed" do
    before do
      run_generator
    end

    it "generates the controllers" do
      assert_file "app/controllers/devise/passwordless/sessions_controller.rb", /Devise::Passwordless::SessionsController/
    end
  end
end
