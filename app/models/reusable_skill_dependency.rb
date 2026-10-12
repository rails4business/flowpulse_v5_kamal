class ReusableSkillDependency < ApplicationRecord
  KINDS = %w[uses requires extends].freeze

  belongs_to :reusable_skill, inverse_of: :reusable_skill_dependencies
  belongs_to :required_skill, class_name: "ReusableSkill", inverse_of: :dependent_skill_dependencies

  validates :required_skill_id, uniqueness: { scope: :reusable_skill_id }
  validates :dependency_kind, inclusion: { in: KINDS }
  validate :skill_cannot_depend_on_itself

  private

    def skill_cannot_depend_on_itself
      errors.add(:required_skill, "non può coincidere con la Skill") if reusable_skill_id == required_skill_id
    end
end
