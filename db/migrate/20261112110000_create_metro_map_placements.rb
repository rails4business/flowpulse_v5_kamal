class CreateMetroMapPlacements < ActiveRecord::Migration[8.1]
  def change
    create_table :metro_maps do |t|
      t.references :domain, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.timestamps
    end

    create_table :metro_map_placements do |t|
      t.references :metro_map, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true
      t.float :x, null: false
      t.float :y, null: false
      t.timestamps
      t.index %i[metro_map_id node_id], unique: true
    end
  end
end
