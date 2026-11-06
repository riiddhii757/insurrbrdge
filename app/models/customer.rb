class Customer < ApplicationRecord
  belongs_to :agency
  has_many :insurance_submissions, dependent: :restrict_with_exception

  validates :legal_name, presence: true
  validates :status, inclusion: { in: %w[prospect active inactive] }
end
