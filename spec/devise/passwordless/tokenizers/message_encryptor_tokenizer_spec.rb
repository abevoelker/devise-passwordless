RSpec.describe Devise::Passwordless::MessageEncryptorTokenizer do
  describe 'encryption and decryption' do
    let(:user_class) { double(:user_class) }
    let(:user) { double(:user, email: 'email@example.com', to_key: [12345]) }

    before do
      Timecop.freeze(Time.utc(2023, 1, 1))

      allow(Devise::Passwordless).to receive(:secret_key).and_return('sekret')
    end

    after do
      Timecop.return
    end

    context "user exists in database" do
      before do
        allow(user_class).to receive(:find_by).and_return(user)
        allow(user_class).to receive(:passwordless_expire_old_tokens_on_sign_in).and_return(false)
      end

      it 'can encrypt and decrypt a resource', freeze_time: Time.utc(2023, 1, 1) do
        token = described_class.encode(user)
        resource, data = described_class.decode(token, user_class)

        expected_decrypt =
          {
            "created_at" => 1672531200.0,
            "data" => {
              "resource" => {
                "email" => "email@example.com",
                "key" => [12345]
              }
            }
          }

        expect(resource).to eq(user)
        expect(data).to eq(expected_decrypt)
      end


      it 'can encrypt and decrypt a resource with extra data supplied', freeze_time: Time.utc(2023, 1, 1) do
        token = described_class.encode(user, extra: { foo: :bar })
        resource, data = described_class.decode(token, user_class)

        expected_decrypt =
          {
            "created_at" => 1672531200.0,
            "data" => {
              "resource" => {
                "email" => "email@example.com",
                "key" => [12345]
              },
              "extra" => {
                "foo" => "bar"
              },
            }
          }

        expect(resource).to eq(user)
        expect(data).to eq(expected_decrypt)
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

        context "passing expire_duration" do
          it "raises InvalidOrExpiredTokenError if token is expired" do
            start = Time.utc(2023, 1, 1)
            token = Timecop.freeze(start) do
              described_class.encode(user)
            end
            Timecop.freeze(start + 4.minutes) do
              expect{described_class.decode(token, user_class, as_of: Time.current, expire_duration: 5.minutes)}.not_to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
            Timecop.freeze(start + 6.minutes) do
              expect{described_class.decode(token, user_class, as_of: Time.current, expire_duration: 5.minutes)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            end
          end
        end

        context "passing as_of" do
          it "raises InvalidOrExpiredTokenError if token is expired" do
            start = Time.utc(2023, 1, 1)
            token = Timecop.freeze(start) do
              described_class.encode(user)
            end
            expect{described_class.decode(token, user_class, as_of: start + 5.minutes, expire_duration: 5.minutes)}.not_to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
            expect{described_class.decode(token, user_class, as_of: start + 6.minutes, expire_duration: 5.minutes)}.to raise_error(Devise::Passwordless::InvalidOrExpiredTokenError)
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
