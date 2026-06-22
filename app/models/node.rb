class Node < ApplicationRecord
  STATUSES = %w[draft published archived].freeze
  VISIBILITIES = %w[public subscription member private].freeze
  VISIBILITY_LABELS = {
    "public" => "Pubblico",
    "subscription" => "Iscrizione gratuita",
    "private" => "Privato",
    "member" => "Member"
  }.freeze

  belongs_to :role_assignment
  belongs_to :parent, class_name: "Node", optional: true
  belongs_to :link_node, class_name: "Node", optional: true
  has_closure_tree order: "position", dependent: :destroy

  has_many :domains, dependent: :nullify
  has_many :traveler_subscriptions, dependent: :destroy
  has_one :content,
    class_name: "NodeContent",
    dependent: :destroy,
    inverse_of: :node

  acts_as_list scope: [:parent_id, :role_assignment_id]

  accepts_nested_attributes_for :content, update_only: true

  before_validation :set_slug, if: -> { slug.blank? && title.present? }
  before_validation :set_node_defaults
  before_validation :inherit_role_assignment_from_parent
  after_initialize :build_default_content, if: :new_record?
  after_save :sync_descendant_role_assignments, if: :saved_change_to_role_assignment_id?
  after_save :sync_domain_role_assignments, if: :saved_change_to_role_assignment_id?

  validates :title, presence: true
  validates :slug, presence: true
  validates :role_assignment, presence: true
  validates :node_type, presence: true
  validates :view_type, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate :role_assignment_matches_parent
  validate :validate_link_node_constraints
  validate :parent_cannot_be_bridge_node

  scope :published_public, -> { where(status: "published", visibility: "public") }
  scope :published_free, -> { where(status: "published", visibility: %w[public subscription]) }

  def self.visibility_label(visibility)
    VISIBILITY_LABELS.fetch(visibility.to_s, visibility.to_s.humanize)
  end

  def resolve_target
    visited = []
    current = self
    while current.link_node_id.present?
      break if visited.include?(current.link_node_id)
      visited << current.link_node_id
      current = current.link_node
    end
    current
  end

  def bridge_node?
    link_node_id.present?
  end

  private

  def set_slug
    self.slug = title.parameterize
  end

  def set_node_defaults
    self.node_type = content_type.presence || "node" if node_type.blank?
    self.view_type = "default" if view_type.blank?
    self.status = "draft" if status.blank?
    self.visibility = "public" if visibility.blank?
  end

  def build_default_content
    build_content if content.blank?
  end

  def inherit_role_assignment_from_parent
    self.role_assignment ||= parent&.role_assignment
  end

  def role_assignment_matches_parent
    return if parent.blank?
    return if role_assignment_id.blank? || parent.role_assignment_id.blank?
    return if role_assignment_id == parent.role_assignment_id

    errors.add(:parent, "deve appartenere allo stesso Creatore")
  end

  def sync_descendant_role_assignments
    descendants.update_all(role_assignment_id: role_assignment_id, updated_at: Time.current)
  end

  def sync_domain_role_assignments
    domains.update_all(role_assignment_id: role_assignment_id, updated_at: Time.current)
  end

  def validate_link_node_constraints
    return if link_node_id.blank?

    if link_node_id == id
      errors.add(:link_node_id, "non può essere il nodo stesso")
    end

    if children.any?
      errors.add(:link_node_id, "non può essere impostato per un nodo che ha già dei figli")
    end

    if role_assignment_id.present? && link_node.present? && link_node.role_assignment_id != role_assignment_id
      errors.add(:link_node_id, "deve appartenere allo stesso Creatore")
    end

    # Verifica cicli circolari
    visited = [id]
    current = link_node
    while current.present?
      if visited.include?(current.id)
        errors.add(:link_node_id, "crea un ciclo/loop infinito di collegamenti")
        break
      end
      visited << current.id
      current = current.link_node
    end
  end

  def parent_cannot_be_bridge_node
    if parent.present? && parent.bridge_node?
      errors.add(:parent_id, "non può essere un nodo ponte (i nodi ponte non possono avere figli)")
    end
  end
end
