class BrandAccess < ApplicationRecord
  STATUSES = %w[active cancelled].freeze

  belongs_to :profile
  belongs_to :source_domain, class_name: "Domain", inverse_of: :originating_brand_accesses
  belongs_to :brand_node, class_name: "Node", inverse_of: :brand_accesses
  has_many :sessions, dependent: :destroy

  before_validation :sync_brand_node_from_source_domain
  before_validation :set_defaults

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :brand_node_id, uniqueness: { scope: :profile_id, message: "ha già un accesso per questo brand" }
  validate :source_domain_has_node
  validate :brand_node_matches_source_domain

  scope :active, -> { where(status: "active") }

  def self.ordered_for(profile:, domain: nil)
    accesses = profile.brand_accesses.active.includes(:source_domain, :brand_node)
    root_node = domain&.node
    list = if root_node.present?
      accesses.where(brand_node_id: root_node.self_and_descendants.select(:id))
    else
      accesses
    end.to_a

    ordered_node_ids = if root_node.present?
      root_node.self_and_descendants.pluck(:id)
    else
      Node.where(id: list.map(&:brand_node_id)).order(:role_assignment_id, :parent_id, :position, :title).pluck(:id)
    end
    node_position = ordered_node_ids.each_with_index.to_h

    list.sort_by do |access|
      [
        node_position.fetch(access.brand_node_id, ordered_node_ids.length),
        access.source_domain.hostname
      ]
    end
  end

  def cancel!
    transaction do
      update!(status: "cancelled")
      sessions.where(revoked_at: nil).update_all(revoked_at: Time.current, updated_at: Time.current)
    end
  end

  def active?
    status == "active"
  end

  private

    def sync_brand_node_from_source_domain
      self.brand_node ||= source_domain&.node
    end

    def set_defaults
      self.status = "active" if status.blank?
      self.joined_at ||= Time.current
    end

    def source_domain_has_node
      return if source_domain.blank? || source_domain.node_id.present?

      errors.add(:source_domain_id, "deve essere collegato a un nodo")
    end

    def brand_node_matches_source_domain
      return if source_domain.blank? || brand_node.blank?
      return if source_domain.node_id == brand_node_id

      errors.add(:brand_node_id, "deve corrispondere al nodo del dominio di provenienza")
    end
end
