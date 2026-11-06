class Quote < ApplicationRecord
  belongs_to :agency
  belongs_to :market_submission

  validates :status, inclusion: { in: %w[received presented accepted rejected expired withdrawn] }
  validates :source, inclusion: { in: %w[carrier aggregator demo] }
  validates :environment, inclusion: { in: %w[demo sandbox production] }
  validates :currency, presence: true
  validates :premium, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :market_submission_belongs_to_agency
  validate :demo_source_is_not_mislabeled

  def simulated?
    source == "demo" || environment == "demo"
  end

  private

  def market_submission_belongs_to_agency
    errors.add(:market_submission, "must belong to the same agency") if market_submission && agency_id != market_submission.agency_id
  end

  def demo_source_is_not_mislabeled
    return unless simulated?

    errors.add(:status, "demo quotes cannot be marked as accepted") if status == "accepted"
  end
end
