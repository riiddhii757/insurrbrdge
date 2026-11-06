class User < ApplicationRecord
  has_secure_password

  has_many :memberships, dependent: :destroy
  has_many :agencies, through: :memberships
  has_many :created_submissions, class_name: "InsuranceSubmission", foreign_key: :created_by_id, dependent: :nullify

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
