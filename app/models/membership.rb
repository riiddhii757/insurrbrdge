class Membership < ApplicationRecord
  belongs_to :agency
  belongs_to :user

  ROLES = %w[agency_admin producer account_manager read_only].freeze

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: %w[active invited suspended] }
  validates :user_id, uniqueness: { scope: :agency_id }
end
