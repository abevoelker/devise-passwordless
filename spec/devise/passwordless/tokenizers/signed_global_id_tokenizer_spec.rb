RSpec.describe Devise::Passwordless::SignedGlobalIDTokenizer do
  describe 'encryption and decryption' do
    let(:secret) { 's3Krit' }

    before do
      Timecop.freeze(Time.utc(2023, 1, 1))
      allow(Devise::Passwordless).to receive(:secret_key).and_return(secret)
      verifier = ActiveSupport::MessageVerifier.new(secret)
      allow(SignedGlobalID).to receive(:verifier).and_return(verifier)

      user = Class.new do
        include GlobalID::Identification

        attr_accessor :email, :id
        def email
          @email
        end
  
        def to_key
          [@id]
        end

        def self.primary_key
          :id
        end

        def self.passwordless_login_within
          5.minutes
        end
      end

      allow(GlobalID).to receive(:app).and_return('foo')
      stub_const('User', user)
    end

    let(:user) { User.new.tap{|x| x.id = 12345; x.email = 'email@example.com'} }
    let(:user_class) { user.class }

    after do
      Timecop.return
    end

    context "user exists in database" do
      before do
        allow(user_class).to receive(:find).and_return(user)
        allow(user_class).to receive(:passwordless_expire_old_tokens_on_sign_in).and_return(false)
      end

      it 'can encrypt and decrypt a resource', freeze_time: Time.utc(2023, 1, 1) do
        token = described_class.encode(user)
        resource, data = described_class.decode(token, user_class)

        expect(resource).to eq(user)
        expect(data).to eq({})
      end

      it "raises InvalidOrExpiredTokenError if token is expired" do
        start = Time.utc(2023, 1, 1)
        token = Timecop.freeze(start) do
          described_class.encode(user)
        end
        Timecop.freeze(start + 21.minutes) do
          expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
        end
      end

      context "custom expiration" do
        context "setting Devise.passwordless_login_within" do
          before do
            allow(Devise).to receive(:passwordless_login_within).and_return(5.minutes)
          end

          it "raises InvalidOrExpiredTokenError if token is expired" do
            start = Time.utc(2023, 1, 1)
            token = Timecop.freeze(start) do
              described_class.encode(user)
            end
            Timecop.freeze(start + 4.minutes) do
              expect{described_class.decode(token, user_class)}.not_to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
            Timecop.freeze(start + 6.minutes) do
              expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
          end
        end

        context "passing expires_in" do
          it "raises InvalidOrExpiredTokenError if token is expired" do
            start = Time.utc(2023, 1, 1)
            token = Timecop.freeze(start) do
              described_class.encode(user, expires_in: 5.minutes)
            end
            Timecop.freeze(start + 4.minutes) do
              expect{described_class.decode(token, user_class)}.not_to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
            Timecop.freeze(start + 6.minutes) do
              expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
          end
        end
      end
    end

    context "decode" do
      context "with invalid token" do
        context "(nil token)" do
          let(:token) { nil }

          it "raises InvalidOrExpiredTokenError" do
            expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
          end
        end

        context "(blank token)" do
          let(:token) { "" }

          it "raises InvalidOrExpiredTokenError" do
            expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
          end
        end

        context "(invalid token)" do
          let(:tokens) { [
            "asdf",
            "asdf:asdf",
            ":asdf",
            "asdf:",
            "asdf:asdf:asdf",
            ":",
          ] }

          it "raises InvalidOrExpiredTokenError" do
            tokens.each do |token|
              expect{described_class.decode(token, user_class)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
          end
        end
      end
    end
  end
end
