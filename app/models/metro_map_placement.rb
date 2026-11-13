class MetroMapPlacement < ApplicationRecord
  belongs_to :metro_map, inverse_of: :placements
  belongs_to :node

  validates :node_id, uniqueness: { scope: :metro_map_id }
  validates :x, :y, numericality: true
end
