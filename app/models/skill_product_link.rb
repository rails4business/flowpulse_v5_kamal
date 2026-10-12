class SkillProductLink < ApplicationRecord
  RELATION_KINDS = %w[contains uses presents schedules related].freeze

  belongs_to :source_product, class_name: "SkillProduct", inverse_of: :outgoing_links
  belongs_to :target_product, class_name: "SkillProduct", inverse_of: :incoming_links

  validates :relation_kind, inclusion: { in: RELATION_KINDS }
  validates :target_product_id, uniqueness: { scope: %i[source_product_id relation_kind] }
  validate :products_must_be_different

  private

    def products_must_be_different
      errors.add(:target_product, "deve essere diverso dal prodotto di partenza") if source_product_id == target_product_id
    end
end
