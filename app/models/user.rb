class User < ApplicationRecord
  has_secure_password

  MAX_FAILED_LOGIN_ATTEMPTS = 10
  LOGIN_LOCK_DURATION = 15.minutes
  PASSWORD_RESET_TTL = 30.minutes

  has_many :memberships, dependent: :destroy
  has_many :agencies, through: :memberships
  has_many :created_submissions, class_name: "InsuranceSubmission", foreign_key: :created_by_id, dependent: :nullify

  before_validation :normalize_email
  before_update :increment_auth_session_version, if: -> { will_save_change_to_password_digest? || will_save_change_to_disabled_at? }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  def login_locked?
    locked_at.present? && locked_at > LOGIN_LOCK_DURATION.ago
  end

  def register_failed_login!
    with_lock do
      return if login_locked?

      attempts = failed_login_attempts.to_i + 1
      update!(
        failed_login_attempts: attempts,
        locked_at: (Time.current if attempts >= MAX_FAILED_LOGIN_ATTEMPTS)
      )
    end
  end

  def reset_failed_login!
    update!(failed_login_attempts: 0, locked_at: nil) if failed_login_attempts.to_i.positive? || locked_at.present?
  end

  def issue_password_reset_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(
      password_reset_digest: Digest::SHA256.hexdigest(token),
      password_reset_sent_at: Time.current
    )
    token
  end

  def password_reset_token_valid?(token)
    return false if password_reset_digest.blank? || password_reset_sent_at.blank?
    return false if password_reset_sent_at < PASSWORD_RESET_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(
      password_reset_digest,
      Digest::SHA256.hexdigest(token.to_s)
    )
  end

  def clear_password_reset_token!
    update!(password_reset_digest: nil, password_reset_sent_at: nil)
  end

  private

  def increment_auth_session_version
    self.auth_session_version = auth_session_version.to_i + 1
  end

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
