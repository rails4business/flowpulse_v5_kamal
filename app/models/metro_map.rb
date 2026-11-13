class MetroMap < ApplicationRecord
  STATUSES = %w[draft published archived].freeze

  belongs_to :domain
  has_many :placements, class_name: "MetroMapPlacement", dependent: :destroy, inverse_of: :metro_map

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
end
