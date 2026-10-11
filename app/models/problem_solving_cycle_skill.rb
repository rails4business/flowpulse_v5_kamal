class ProblemSolvingCycleSkill < ApplicationRecord
  belongs_to :problem_solving_cycle
  belongs_to :reusable_skill

  validates :reusable_skill_id, uniqueness: { scope: :problem_solving_cycle_id }
end
