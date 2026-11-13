class AddLaneContainerToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :lane_container, :boolean, default: false, null: false
    add_index :nodes, :lane_container
  end
end
