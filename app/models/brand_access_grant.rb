class BrandAccessGrant < ApplicationRecord
  STATUSES = %w[active revoked].freeze

  belongs_to :brand_access
  belongs_to :node
  belongs_to :brand_request, optional: true
  belongs_to :granted_by_profile, class_name: "Profile", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :node_id, uniqueness: { scope: :brand_access_id }
  validate :node_is_inside_access_brand

  scope :active, -> { where(status: "active") }

  def active?
    status == "active"
  end

  private

    def node_is_inside_access_brand
      return if brand_access.blank? || node.blank?
      return if node == brand_access.brand_node || node.ancestors.exists?(brand_access.brand_node_id)

      errors.add(:node, "deve appartenere al BrandAccess")
    end
end
