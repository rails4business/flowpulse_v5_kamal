class AddCollapsedToMetroMapPlacements < ActiveRecord::Migration[8.1]
  def change
    add_column :metro_map_placements, :collapsed, :boolean, default: false, null: false
  end
end
