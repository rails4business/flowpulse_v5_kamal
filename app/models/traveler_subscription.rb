class TravelerSubscription < ApplicationRecord
  STATUSES = %w[active cancelled].freeze

  belongs_to :profile
  belongs_to :domain
  belongs_to :node

  before_validation :sync_node_from_domain
  before_validation :set_defaults

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :domain_id, uniqueness: { scope: :profile_id }
  validate :domain_has_node
  validate :node_matches_domain

  scope :active, -> { where(status: "active") }

  def self.ordered_for(profile:, domain: nil)
    subscriptions = profile.traveler_subscriptions.active.includes(:domain, :node)
    root_node = domain&.node
    list = if root_node.present?
      subscriptions.where(node_id: root_node.self_and_descendants.select(:id))
    else
      subscriptions
    end.to_a

    ordered_node_ids = if root_node.present?
      root_node.self_and_descendants.pluck(:id)
    else
      Node.where(id: list.map(&:node_id)).order(:role_assignment_id, :parent_id, :position, :title).pluck(:id)
    end
    node_position = ordered_node_ids.each_with_index.to_h

    list.sort_by do |subscription|
      [
        node_position.fetch(subscription.node_id, ordered_node_ids.length),
        subscription.domain.hostname
      ]
    end
  end

  def cancel!
    update!(status: "cancelled")
  end

  def active?
    status == "active"
  end

  private

  def sync_node_from_domain
    self.node ||= domain&.node
  end

  def set_defaults
    self.status = "active" if status.blank?
    self.subscribed_at ||= Time.current
  end

  def domain_has_node
    return if domain.blank? || domain.node_id.present?

    errors.add(:domain_id, "deve essere collegato a un nodo")
  end

  def node_matches_domain
    return if domain.blank? || node.blank?
    return if domain.node_id == node_id

    errors.add(:node_id, "deve corrispondere al nodo del dominio")
  end
end
