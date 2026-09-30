class NodeEvent < ApplicationRecord
  KINDS = %w[created started consolidated cut resumed updated fixed].freeze

  belongs_to :node
  belongs_to :performed_by_user, class_name: "User", optional: true

  attribute :happened_at, default: -> { Time.current }
  before_validation :set_public_id, on: :create

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :happened_at, presence: true
  validates :public_id, presence: true, uniqueness: true

  scope :chronological, -> { order(:happened_at, :id) }

  private

    def set_public_id
      self.public_id ||= SecureRandom.uuid
    end
end
