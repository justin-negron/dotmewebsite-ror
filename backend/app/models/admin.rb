class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, if: :password_digest_changed?

  normalizes :email, with: ->(email) { email.strip.downcase }

  def invalidate_refresh_token!
    update_columns(refresh_token_jti: nil, refresh_token_exp: nil)
  end

  def refresh_token_valid?(jti)
    refresh_token_jti == jti && refresh_token_exp&.future?
  end
end
