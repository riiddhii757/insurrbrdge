class User < ApplicationRecord
  has_secure_password
  encrypts :totp_secret

  MAX_FAILED_LOGIN_ATTEMPTS = 10
  LOGIN_LOCK_DURATION = 15.minutes
  PASSWORD_RESET_TTL = 30.minutes
  EMAIL_VERIFICATION_TTL = 24.hours
  MFA_RECOVERY_CODE_COUNT = 10

  has_many :memberships, dependent: :destroy
  has_many :agencies, through: :memberships
  has_many :created_submissions, class_name: "InsuranceSubmission", foreign_key: :created_by_id, dependent: :nullify
  has_many :mfa_recovery_codes, dependent: :destroy

  before_validation :normalize_email
  before_update :increment_auth_session_version, if: -> { will_save_change_to_password_digest? || will_save_change_to_disabled_at? }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  def login_locked?
    locked_at.present? && locked_at > LOGIN_LOCK_DURATION.ago
  end

  def email_verified?
    email_verified_at.present?
  end

  def mfa_enabled?
    totp_enabled_at.present? && totp_secret.present?
  end

  def begin_mfa_setup!
    secret = base32_encode(SecureRandom.random_bytes(20))
    update!(totp_secret: secret, totp_enabled_at: nil)
    secret
  end

  def enable_mfa!(code)
    return false unless totp_secret.present? && valid_totp_code?(code)

    codes = Array.new(MFA_RECOVERY_CODE_COUNT) { SecureRandom.alphanumeric(12).upcase }
    transaction do
      mfa_recovery_codes.delete_all
      codes.each { |value| mfa_recovery_codes.create!(digest: Digest::SHA256.hexdigest(value)) }
      update!(totp_enabled_at: Time.current)
    end
    codes
  end

  def verify_mfa_code(code)
    return false unless mfa_enabled?

    return true if valid_totp_code?(code)

    digest = Digest::SHA256.hexdigest(code.to_s.upcase.delete(" -"))
    MfaRecoveryCode.transaction do
      recovery = mfa_recovery_codes.lock.find_by(digest: digest, used_at: nil)
      return false unless recovery

      recovery.update!(used_at: Time.current)
      true
    end
  end

  def disable_mfa!
    update!(totp_secret: nil, totp_enabled_at: nil)
    mfa_recovery_codes.delete_all
  end

  def valid_totp_code?(code, at: Time.current)
    value = code.to_s
    return false unless value.match?(/\A\d{6}\z/) && totp_secret.present?

    counter = at.to_i / 30
    (-1..1).any? { |offset| ActiveSupport::SecurityUtils.secure_compare(totp_code(counter + offset), value) }
  end

  def issue_email_verification_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(email_verification_digest: Digest::SHA256.hexdigest(token), email_verification_sent_at: Time.current)
    token
  end

  def email_verification_token_valid?(token)
    return false if email_verification_digest.blank? || email_verification_sent_at.blank?
    return false if email_verification_sent_at < EMAIL_VERIFICATION_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(email_verification_digest, Digest::SHA256.hexdigest(token.to_s))
  end

  def register_failed_login!
    with_lock do
      return if login_locked?

      attempts = failed_login_attempts.to_i + 1
      update!(failed_login_attempts: attempts, locked_at: (Time.current if attempts >= MAX_FAILED_LOGIN_ATTEMPTS))
    end
  end

  def reset_failed_login!
    update!(failed_login_attempts: 0, locked_at: nil) if failed_login_attempts.to_i.positive? || locked_at.present?
  end

  def issue_password_reset_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(password_reset_digest: Digest::SHA256.hexdigest(token), password_reset_sent_at: Time.current)
    token
  end

  def password_reset_token_valid?(token)
    return false if password_reset_digest.blank? || password_reset_sent_at.blank?
    return false if password_reset_sent_at < PASSWORD_RESET_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(password_reset_digest, Digest::SHA256.hexdigest(token.to_s))
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

  def totp_code(counter)
    key = base32_decode(totp_secret)
    digest = OpenSSL::HMAC.digest("SHA1", key, [counter].pack("Q>"))
    offset = digest.getbyte(-1) & 0x0f
    binary = digest.byteslice(offset, 4).unpack1("N") & 0x7fffffff
    format("%06d", binary % 1_000_000)
  end

  def base32_encode(bytes)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    bytes.unpack1("B*").scan(/.{1,5}/).map { |chunk| alphabet[chunk.ljust(5, "0").to_i(2)] }.join
  end

  def base32_decode(value)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    bits = value.chars.map { |char| alphabet.index(char).to_s(2).rjust(5, "0") }.join
    [bits[0, bits.length / 8 * 8]].pack("B*")
  end
end
