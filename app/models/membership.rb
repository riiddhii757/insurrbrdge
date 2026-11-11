class Membership < ApplicationRecord
  belongs_to :agency
  belongs_to :user

  ROLES = %w[agency_admin producer account_manager read_only].freeze

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: %w[active invited suspended] }
  validates :user_id, uniqueness: { scope: :agency_id }

  after_commit :revoke_user_sessions, on: %i[update destroy], if: :access_changed?

  private

  def access_changed?
    destroyed? || saved_change_to_status?
  end

  def revoke_user_sessions
    user&.increment!(:auth_session_version)
  end
end
