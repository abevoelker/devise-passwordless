RSpec.describe Devise::Passwordless::LoginToken do
  describe 'encryption and decryption' do
    let(:user) { double(:user, email: 'email@example.com', to_key: [12345]) }

    before do
      Timecop.freeze(Time.utc(2023, 1, 1))

      allow(described_class).to receive(:secret_key).and_return('sekret')
    end

    after do
      Timecop.return
    end

    it 'can encrypt and decrypt a resource', freeze_time: Time.utc(2023, 1, 1) do
      token = described_class.encode(user)
      decrypted = described_class.decode(token)

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

      expect(decrypted).to eq(expected_decrypt)
    end

    it 'can encrypt and decrypt a resource with extra data supplied', freeze_time: Time.utc(2023, 1, 1) do
      token = described_class.encode(user, { foo: :bar })
      decrypted = described_class.decode(token)

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

      expect(decrypted).to eq(expected_decrypt)
    end

    it "raises InvalidOrExpiredTokenError if token is expired" do
      start = Time.utc(2023, 1, 1)
      token = Timecop.freeze(start) do
        Devise::Passwordless::LoginToken.encode(user)
      end
      Timecop.freeze(start + 21.minutes) do
        expect{Devise::Passwordless::LoginToken.decode(token)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
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
            Devise::Passwordless::LoginToken.encode(user)
          end
          Timecop.freeze(start + 4.minutes) do
            expect{Devise::Passwordless::LoginToken.decode(token)}.not_to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          end
          Timecop.freeze(start + 6.minutes) do
            expect{Devise::Passwordless::LoginToken.decode(token)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          end
        end
      end

      context "passing expire_duration" do
        it "raises InvalidOrExpiredTokenError if token is expired" do
          start = Time.utc(2023, 1, 1)
          token = Timecop.freeze(start) do
            Devise::Passwordless::LoginToken.encode(user)
          end
          Timecop.freeze(start + 4.minutes) do
            expect{Devise::Passwordless::LoginToken.decode(token, Time.current, 5.minutes)}.not_to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          end
          Timecop.freeze(start + 6.minutes) do
            expect{Devise::Passwordless::LoginToken.decode(token, Time.current, 5.minutes)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          end
        end
      end

      context "passing as_of" do
        it "raises InvalidOrExpiredTokenError if token is expired" do
          start = Time.utc(2023, 1, 1)
          token = Timecop.freeze(start) do
            Devise::Passwordless::LoginToken.encode(user)
          end
          expect{Devise::Passwordless::LoginToken.decode(token, start + 5.minutes, 5.minutes)}.not_to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          expect{Devise::Passwordless::LoginToken.decode(token, start + 6.minutes, 5.minutes)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
        end
      end
    end

    context "decode" do
      context "with invalid token" do
        context "(nil token)" do
          let(:token) { nil }

          it "raises InvalidOrExpiredTokenError" do
            expect{Devise::Passwordless::LoginToken.decode(token)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
          end
        end

        context "(blank token)" do
          let(:token) { "" }

          it "raises InvalidOrExpiredTokenError" do
            expect{Devise::Passwordless::LoginToken.decode(token)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
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
              expect{Devise::Passwordless::LoginToken.decode(token)}.to raise_error(Devise::Passwordless::LoginToken::InvalidOrExpiredTokenError)
            end
          end
        end
      end
    end
  end
end
