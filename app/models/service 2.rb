class Service < ApplicationRecord
  belongs_to :node
  belongs_to :created_by_user, class_name: "User"
  has_many :data_sessions, dependent: :restrict_with_error

  before_validation :set_slug, if: -> { slug.blank? && title.present? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: { scope: :node_id }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }

  scope :active, -> { where(active: true) }

  def display_label
    "#{node.title} · #{title}"
  end

  private

    def set_slug
      self.slug = "#{node&.slug}-#{title}".parameterize
    end
end
