class BrandProcess < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  belongs_to :node
  belongs_to :created_by_user, class_name: "User"
  has_many :data_experiences, dependent: :nullify

  before_validation :set_slug, if: -> { slug.blank? && title.present? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: { scope: :node_id }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }

  private

    def set_slug
      self.slug = title.parameterize
    end
end
