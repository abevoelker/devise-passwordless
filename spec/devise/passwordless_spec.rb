RSpec.describe Devise::Passwordless do
  it "has a version number" do
    expect(Devise::Passwordless::VERSION).not_to be nil
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
