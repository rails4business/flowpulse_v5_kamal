class ReusableSkill < ApplicationRecord
  STATUSES = %w[idea design development testing available maintenance archived].freeze
  CATEGORIES = {
    "contents" => "Contenuti",
    "courses" => "Corsi",
    "paths" => "Percorsi",
    "worksheets" => "Schede ed esercizi",
    "contacts" => "Contatti e richieste",
    "places" => "Luoghi e centri",
    "events" => "Eventi",
    "commitments" => "Impegni e agenda",
    "bookings" => "Prenotazioni",
    "services" => "Servizi",
    "payments" => "Pagamenti e accessi",
    "other" => "Altro"
  }.freeze
  STATUS_LABELS = {
    "idea" => "Idea", "design" => "Progettazione", "development" => "Sviluppo",
    "testing" => "Test", "available" => "Disponibile", "maintenance" => "Manutenzione",
    "archived" => "Archiviata"
  }.freeze

  belongs_to :owner_profile, class_name: "Profile", inverse_of: :reusable_skills
  belongs_to :responsible_profile, class_name: "Profile", optional: true
  has_many :reusable_skill_nodes, dependent: :destroy
  has_many :nodes, through: :reusable_skill_nodes
  has_many :skill_products, through: :reusable_skill_nodes
  has_many :problem_solving_cycle_skills, dependent: :destroy
  has_many :problem_solving_cycles, through: :problem_solving_cycle_skills
  has_many :reusable_skill_dependencies, dependent: :destroy, inverse_of: :reusable_skill
  has_many :required_skills, through: :reusable_skill_dependencies, source: :required_skill
  has_many :dependent_skill_dependencies,
           class_name: "ReusableSkillDependency",
           foreign_key: :required_skill_id,
           dependent: :destroy,
           inverse_of: :required_skill
  has_many :dependent_skills, through: :dependent_skill_dependencies, source: :reusable_skill

  before_validation :set_slug, if: -> { slug.blank? && title.present? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: { scope: :owner_profile_id }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(updated_at: :desc) }

  def activation_for(node, active_only: true)
    relation = reusable_skill_nodes.where(node:)
    relation = relation.where(status: "active") if active_only
    relation.first
  end

  def category_label
    CATEGORIES.fetch(category)
  end

  def status_label
    STATUS_LABELS.fetch(status)
  end

  private

    def set_slug
      self.slug = title.to_s.parameterize
    end
end
