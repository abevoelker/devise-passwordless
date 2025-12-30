RSpec.describe Devise::Passwordless do
  it "has a version number" do
    expect(Devise::Passwordless::VERSION).not_to be nil
  end

  describe ".secret_key" do
    before { allow(Devise).to receive(:secret_key).and_return("default_secret") }

    it "returns passwordless_secret_key when present" do
      allow(Devise).to receive(:passwordless_secret_key).and_return("passwordless_secret")
      expect(described_class.secret_key).to eq("passwordless_secret")
    end

    it "resolves callable passwordless_secret_key at runtime" do
      allow(Devise).to receive(:passwordless_secret_key).and_return(-> { "dynamic_secret" })
      expect(described_class.secret_key).to eq("dynamic_secret")
    end

    it "falls back to Devise.secret_key when passwordless_secret_key is blank" do
      allow(Devise).to receive(:passwordless_secret_key).and_return(nil)
      expect(described_class.secret_key).to eq("default_secret")
    end
  end

  context "check_filter_parameters" do
    let(:warn_msg) { Devise::Passwordless::FILTER_PARAMS_WARNING + "\n" }

    context "symbol keys" do
      it "warns if :token is not filtered" do
        params = [:password, :password_confirmation]
        expect { Devise::Passwordless.check_filter_parameters(params) }.to output(warn_msg).to_stderr
      end

      it "doesn't warn if :token is filtered" do
        params = [:token, :password, :password_confirmation]
        expect { Devise::Passwordless.check_filter_parameters(params) }.not_to output(warn_msg).to_stderr
      end
    end

    context "string keys" do
      it "warns if :token is not filtered" do
        params = ["password", "password_confirmation"]
        expect { Devise::Passwordless.check_filter_parameters(params) }.to output(warn_msg).to_stderr
      end

      it "doesn't warn if :token is filtered" do
        params = ["token", "password", "password_confirmation"]
        expect { Devise::Passwordless.check_filter_parameters(params) }.not_to output(warn_msg).to_stderr
      end
    end

    context "regex keys" do
      it "doesn't warn if :token is not filtered" do
        params = [:password, :password_confirmation, /foo/]
        expect { Devise::Passwordless.check_filter_parameters(params) }.not_to output(warn_msg).to_stderr
      end

      it "doesn't warn if :token is filtered" do
        params = [:token, "token", :password, :password_confirmation, /foo/]
        expect { Devise::Passwordless.check_filter_parameters(params) }.not_to output(warn_msg).to_stderr
      end
    end
  end
end
