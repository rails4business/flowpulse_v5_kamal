class DataCommitmentImport < ApplicationRecord
  belongs_to :uploaded_by_user, class_name: "User"
  belongs_to :target_profile, class_name: "Profile", optional: true
  validates :status, inclusion: { in: %w[pending applied rejected] }
  validates :source_name, presence: true

  scope :awaiting_profile_confirmation, -> { where(status: "pending").where.not(target_profile_id: nil) }
end
