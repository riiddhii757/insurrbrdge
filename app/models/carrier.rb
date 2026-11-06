class Carrier < ApplicationRecord
  has_many :market_submissions, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :integration_status, inclusion: { in: %w[planned sandbox_ready production_pending live paused] }

  def supports_submission?(submission)
    return false unless Array(supported_lines).include?(submission.line_of_business)
    return false if submission.state.blank?

    Array(supported_states).include?(submission.state)
  end
end
