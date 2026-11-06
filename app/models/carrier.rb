class Carrier < ApplicationRecord
  has_many :market_submissions, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :integration_status, inclusion: { in: %w[planned sandbox_ready production_pending live paused] }
end
