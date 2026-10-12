class SkillProduct < ApplicationRecord
  STATUSES = %w[draft published archived].freeze
  VISIBILITIES = %w[public subscription purchase private].freeze
  FORMATS = %w[markdown yaml json external].freeze

  belongs_to :reusable_skill_node, inverse_of: :skill_products
  belongs_to :created_by_profile, class_name: "Profile", inverse_of: :created_skill_products
  has_one :reusable_skill, through: :reusable_skill_node
  has_one :node, through: :reusable_skill_node

  has_many :outgoing_links,
           class_name: "SkillProductLink",
           foreign_key: :source_product_id,
           dependent: :destroy,
           inverse_of: :source_product
  has_many :linked_products, through: :outgoing_links, source: :target_product
  has_many :incoming_links,
           class_name: "SkillProductLink",
           foreign_key: :target_product_id,
           dependent: :destroy,
           inverse_of: :target_product
  has_many :source_products, through: :incoming_links, source: :source_product

  before_validation :set_slug, if: -> { slug.blank? && title.present? }
  before_validation :normalize_source_path
  before_validation :set_published_at

  validates :title, :slug, presence: true
  validates :slug,
            uniqueness: { scope: :reusable_skill_node_id },
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :format, inclusion: { in: FORMATS }
  validates :source_path, uniqueness: true, allow_nil: true
  validate :source_path_is_relative_and_safe

  scope :recent_first, -> { order(updated_at: :desc) }
  scope :publicly_available, -> { where(status: "published", visibility: "public") }

  private

    def set_slug
      self.slug = title.to_s.parameterize
    end

    def normalize_source_path
      self.source_path = source_path.to_s.strip.presence
    end

    def set_published_at
      self.published_at ||= Time.current if status == "published"
    end

    def source_path_is_relative_and_safe
      return if source_path.blank?

      pathname = Pathname(source_path)
      errors.add(:source_path, "deve essere relativo alla repository") if pathname.absolute?
      errors.add(:source_path, "non può uscire dalla repository") if pathname.each_filename.include?("..")
      errors.add(:source_path, "deve trovarsi sotto config/data/") unless source_path.start_with?("config/data/")
    end
end
