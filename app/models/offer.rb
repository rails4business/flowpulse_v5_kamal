class Offer < ApplicationRecord
  STATUSES = %w[draft published archived].freeze
  PREVIOUS_PURCHASE_MODES = %w[none credit discount].freeze

  belongs_to :metro_line, optional: true
  belongs_to :line_node, class_name: "Node", optional: true
  belongs_to :start_node, class_name: "Node"
  belongs_to :end_node, class_name: "Node"

  before_validation :normalize_included_offer_slugs

  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :previous_purchase_mode, inclusion: { in: PREVIOUS_PURCHASE_MODES }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :cannot_include_itself
  validate :has_line_reference

  scope :published, -> { where(status: "published") }

  def nodes
    Node.where("? = ANY(offer_slugs)", slug)
  end

  def included_offers
    self.class.where(slug: included_offer_slugs)
  end

  private

    def normalize_included_offer_slugs
      self.included_offer_slugs = Array(included_offer_slugs).filter_map { |value| value.to_s.strip.presence }.uniq
    end

    def cannot_include_itself
      errors.add(:included_offer_slugs, "non può includere l'offerta stessa") if slug.present? && included_offer_slugs.include?(slug)
    end

    def has_line_reference
      errors.add(:base, "deve appartenere a una linea Node") if line_node.blank? && metro_line.blank?
    end
end
