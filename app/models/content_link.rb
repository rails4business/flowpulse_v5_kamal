# Legame verso un Content che non è genitore/figlio: da un altro Content
# (professionista → metodica) oppure da un Node (corso introduttivo → metodica).
class ContentLink < ApplicationRecord
  belongs_to :source_content, class_name: "Content", optional: true, inverse_of: :outgoing_links
  belongs_to :source_node, class_name: "Node", optional: true, inverse_of: :outgoing_content_links
  belongs_to :target_content, class_name: "Content", inverse_of: :incoming_links

  validates :kind, presence: true, format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :exactly_one_source
  validate :not_linked_to_itself

  def source
    source_content || source_node
  end

  private

    def exactly_one_source
      return if [source_content_id, source_node_id].compact.one?

      errors.add(:base, "Indica un contenuto oppure un node di partenza, non entrambi")
    end

    def not_linked_to_itself
      errors.add(:target_content, "non può essere uguale al contenuto di partenza") if source_content_id.present? && source_content_id == target_content_id
    end
end
