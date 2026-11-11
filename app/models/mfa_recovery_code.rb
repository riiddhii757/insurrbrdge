class MfaRecoveryCode < ApplicationRecord
  belongs_to :user

  validates :digest, presence: true, uniqueness: true
end
