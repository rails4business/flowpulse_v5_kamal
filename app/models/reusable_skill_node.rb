class ReusableSkillNode < ApplicationRecord
  STATUSES = %w[draft active suspended].freeze

  belongs_to :reusable_skill
  belongs_to :node
  belongs_to :activated_by_profile, class_name: "Profile", optional: true
  has_many :skill_products, dependent: :restrict_with_error, inverse_of: :reusable_skill_node
  validates :node_id, uniqueness: { scope: :reusable_skill_id }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
end
