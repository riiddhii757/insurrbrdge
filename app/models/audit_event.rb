class AuditEvent < ApplicationRecord
  belongs_to :agency
  belongs_to :user, optional: true

  validates :action, :record_type, presence: true
end
