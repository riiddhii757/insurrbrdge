class InsuranceSubmission < ApplicationRecord
  belongs_to :agency
  belongs_to :customer
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
  has_many :market_submissions, dependent: :destroy

  validates :reference, presence: true, uniqueness: true
  validates :line_of_business, inclusion: { in: %w[general_liability commercial_property business_owners workers_compensation commercial_auto professional_liability] }
  validates :status, inclusion: { in: %w[draft validating ready marketing partially_quoted quoted needs_information markets_reviewed declined selected bind_requested bound not_taken] }
  validate :customer_belongs_to_agency

  before_validation :assign_reference, on: :create

  private

  def assign_reference
    self.reference ||= "IB-#{SecureRandom.hex(5).upcase}"
  end

  def customer_belongs_to_agency
    errors.add(:customer, "must belong to the same agency") if customer && agency_id != customer.agency_id
  end
end
