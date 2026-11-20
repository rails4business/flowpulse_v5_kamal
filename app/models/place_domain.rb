# Un luogo in un dominio, con il Content facoltativo che lo racconta lì (es. la scheda del centro).
class PlaceDomain < ApplicationRecord
  belongs_to :place, inverse_of: :place_domains
  belongs_to :domain
  belongs_to :content, optional: true

  validates :domain_id, uniqueness: { scope: :place_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :content_belongs_to_domain

  private

    # Il Content deve stare nel node del dominio o in uno dei suoi discendenti.
    def content_belongs_to_domain
      return if content.blank? || domain.blank?

      root = domain.resolved_node
      return if root && root.self_and_descendants.where(id: content.node_id).exists?

      errors.add(:content, "deve appartenere a un node del dominio")
    end
end
