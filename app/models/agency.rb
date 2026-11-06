class Agency < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :customers, dependent: :restrict_with_exception
  has_many :insurance_submissions, dependent: :restrict_with_exception
  has_many :market_submissions, dependent: :restrict_with_exception
  has_many :quotes, dependent: :restrict_with_exception
  has_many :audit_events, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
end
