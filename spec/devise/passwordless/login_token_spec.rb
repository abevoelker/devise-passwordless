require 'timecop'

RSpec.describe Devise::Passwordless::LoginToken do
  describe 'encryption and decryption' do
    let(:user) { double(:user, email: 'email@example.com', to_key: 12345) }

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
              "key" => 12345
            }
          }
        }

      expect(decrypted).to eq(expected_decrypt)
    end

    it 'can encrypt and decrpt a resource with extra data supplied', freeze_time: Time.utc(2023, 1, 1) do
      token = described_class.encode(user, { foo: :bar })
      decrypted = described_class.decode(token)

      expected_decrypt =
        {
          "created_at" => 1672531200.0,
          "data" => {
            "resource" => {
              "email" => "email@example.com",
              "key" => 12345
            },
            "extra" => {
              "foo" => "bar"
            },
          }
        }

      expect(decrypted).to eq(expected_decrypt)
    end
  end
end
