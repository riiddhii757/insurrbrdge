class MarketSubmission < ApplicationRecord
  belongs_to :agency
  belongs_to :insurance_submission
  belongs_to :carrier
  has_many :quotes, dependent: :restrict_with_exception

  validates :status, inclusion: { in: %w[queued appetite_check eligible ineligible referred needs_information submitting submitted quoted declined error bind_requested bound] }
  validates :environment, inclusion: { in: %w[demo sandbox production] }
  validate :submission_belongs_to_agency

  private

  def submission_belongs_to_agency
    errors.add(:insurance_submission, "must belong to the same agency") if insurance_submission && agency_id != insurance_submission.agency_id
  end
end
