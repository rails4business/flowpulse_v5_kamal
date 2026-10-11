class ReusableSkillNode < ApplicationRecord
  belongs_to :reusable_skill
  belongs_to :node

  validates :node_id, uniqueness: { scope: :reusable_skill_id }
end
