class ProfessionalCalendar < ApplicationRecord
  COLORS = %w[slate sky blue rose amber emerald violet].freeze

  belongs_to :context_node, class_name: "Node", inverse_of: :context_professional_calendars
  belongs_to :professional_node, class_name: "Node", inverse_of: :professional_calendars
  belongs_to :created_by_user, class_name: "User"
  has_many :data_sessions, dependent: :restrict_with_error

  before_validation :set_slug, if: -> { slug.blank? && title.present? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :color, inclusion: { in: COLORS }
  validate :owner_is_professional

  scope :active, -> { where(active: true) }

  def display_label
    "#{context_node.title} · #{title}"
  end

  def full_label
    "#{professional_node.title} · #{display_label}"
  end

  private

    def set_slug
      self.slug = "#{context_node&.slug}-#{title}".parameterize
    end

    def owner_is_professional
      return if professional_node.blank? || professional_node.professional?

      errors.add(:professional_node, "deve essere un nodo professionale")
    end
end
