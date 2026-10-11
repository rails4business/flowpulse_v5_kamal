class ProblemSolvingCycle < ApplicationRecord
  STATUSES = %w[backlog active resolved closed].freeze
  STEPS = [
    ["identify", "Definisci chiaramente il problema"],
    ["isolate", "Isola una parte affrontabile"],
    ["possible_solutions", "Immagina le possibili soluzioni"],
    ["minimum_solution", "Scegli la soluzione minima"],
    ["self_test", "Provala su di te"],
    ["small_group_test", "Provala con poche persone"],
    ["feedback", "Raccogli feedback e correggi"],
    ["validate", "Verifica la soluzione"],
    ["share", "Diffondila a chi ha lo stesso problema"],
    ["close", "Chiudi, automatizza oppure riapri il ciclo"]
  ].freeze

  belongs_to :owner_profile, class_name: "Profile", inverse_of: :problem_solving_cycles
  belongs_to :responsible_profile, class_name: "Profile", optional: true
  has_many :problem_solving_cycle_nodes, dependent: :destroy
  has_many :nodes, through: :problem_solving_cycle_nodes
  has_many :problem_solving_cycle_skills, dependent: :destroy
  has_many :reusable_skills, through: :problem_solving_cycle_skills
  has_many :data_commitments,
    as: :subject,
    class_name: "Brands::Impegno::Commitment",
    dependent: :restrict_with_error

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :status, uniqueness: { scope: :owner_profile_id, message: "consente un solo problema attivo alla volta" }, if: :active?
  validates :current_step, numericality: { only_integer: true, in: 0..STEPS.size }

  scope :recent_first, -> { order(updated_at: :desc) }

  def active?
    status == "active"
  end

  def completed_steps
    STEPS.first(current_step)
  end

  def current_step_definition
    STEPS[current_step]
  end
end
