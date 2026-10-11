class ProblemSolvingCycleNode < ApplicationRecord
  belongs_to :problem_solving_cycle
  belongs_to :node

  validates :node_id, uniqueness: { scope: :problem_solving_cycle_id }
end
