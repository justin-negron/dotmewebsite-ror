require 'rails_helper'

RSpec.describe JwtService do
  let(:admin) { create(:admin) }

  describe '.encode_access_token' do
    it 'returns a valid JWT string' do
      token = described_class.encode_access_token(admin)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'encodes the correct payload' do
      freeze_time do
        token = described_class.encode_access_token(admin)
        payload = described_class.decode(token)

        expect(payload['admin_id']).to eq(admin.id)
        expect(payload['type']).to eq('access')
        expect(payload['jti']).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
        expect(payload['exp']).to eq(15.minutes.from_now.to_i)
        expect(payload['iat']).to eq(Time.current.to_i)
      end
    end
  end

  describe '.encode_refresh_token' do
    it 'returns a valid JWT string' do
      token = described_class.encode_refresh_token(admin)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'stores JTI on admin record' do
      token = described_class.encode_refresh_token(admin)
      payload = described_class.decode(token)
      expect(admin.reload.refresh_token_jti).to eq(payload['jti'])
    end

    it 'sets refresh_token_exp on admin record' do
      described_class.encode_refresh_token(admin)
      expect(admin.reload.refresh_token_exp).to be_within(5.seconds).of(7.days.from_now)
    end

    it 'encodes type as refresh' do
      token = described_class.encode_refresh_token(admin)
      payload = described_class.decode(token)
      expect(payload['type']).to eq('refresh')
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = described_class.encode_access_token(admin)
      payload = described_class.decode(token)

      expect(payload).to be_a(HashWithIndifferentAccess)
      expect(payload['admin_id']).to eq(admin.id)
    end

    it 'raises AuthenticationError for expired token' do
      token = travel_to(1.hour.ago) { described_class.encode_access_token(admin) }

      expect { described_class.decode(token) }.to raise_error(
        JwtService::AuthenticationError, /expired/i
      )
    end

    it 'raises AuthenticationError for invalid token' do
      expect { described_class.decode('garbage.token.here') }.to raise_error(
        JwtService::AuthenticationError, /\AInvalid token:/
      )
    end

    it 'raises AuthenticationError for tampered token' do
      token = described_class.encode_access_token(admin)
      tampered = token[0...-5] + 'XXXXX'

      expect { described_class.decode(tampered) }.to raise_error(
        JwtService::AuthenticationError, /\AInvalid token:/
      )
    end

    it 'rejects an unsigned token' do
      token = JWT.encode({ admin_id: admin.id, type: 'access', exp: 1.hour.from_now.to_i }, nil, 'none')

      expect { described_class.decode(token) }.to raise_error(
        JwtService::AuthenticationError, /\AInvalid token:/
      )
    end
  end
end
