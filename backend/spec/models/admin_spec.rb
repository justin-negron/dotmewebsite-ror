require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'validations' do
    subject { build(:admin) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
  end

  describe 'email normalization' do
    it 'downcases and strips whitespace' do
      admin = create(:admin, email: '  Admin@Example.COM  ')
      expect(admin.email).to eq('admin@example.com')
    end
  end

  describe '#refresh_token_valid?' do
    let(:admin) { create(:admin) }

    it 'returns true when JTI matches and not expired' do
      admin.update_columns(refresh_token_jti: 'abc', refresh_token_exp: 1.day.from_now)
      expect(admin.refresh_token_valid?('abc')).to be true
    end

    it 'returns false when JTI does not match' do
      admin.update_columns(refresh_token_jti: 'abc', refresh_token_exp: 1.day.from_now)
      expect(admin.refresh_token_valid?('wrong')).to be false
    end

    it 'returns false when token is expired' do
      admin.update_columns(refresh_token_jti: 'abc', refresh_token_exp: 1.day.ago)
      expect(admin.refresh_token_valid?('abc')).to be false
    end

    it 'returns false when no refresh token exists' do
      expect(admin.refresh_token_valid?('abc')).to be false
    end
  end

  describe '#invalidate_refresh_token!' do
    it 'clears refresh token fields' do
      admin = create(:admin)
      admin.update_columns(refresh_token_jti: 'abc', refresh_token_exp: 1.day.from_now)

      admin.invalidate_refresh_token!

      admin.reload
      expect(admin.refresh_token_jti).to be_nil
      expect(admin.refresh_token_exp).to be_nil
    end
  end
end
