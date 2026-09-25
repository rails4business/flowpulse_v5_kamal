class ClassifyNodesAsProfessionalOrProject < ActiveRecord::Migration[8.1]
  def up
    rename_column :nodes, :node_type, :legacy_node_type
    add_column :nodes, :node_type, :integer, null: false, default: 1

    execute <<~SQL.squish
      UPDATE nodes
      SET node_type = CASE WHEN professional = TRUE THEN 0 ELSE 1 END
    SQL

    remove_column :nodes, :professional, :boolean
    remove_column :nodes, :legacy_node_type, :string
    add_index :nodes, :node_type
  end

  def down
    remove_index :nodes, :node_type
    add_column :nodes, :professional, :boolean, null: false, default: false
    add_column :nodes, :legacy_node_type, :string, null: false, default: "node"

    execute <<~SQL.squish
      UPDATE nodes
      SET professional = CASE WHEN node_type = 0 THEN TRUE ELSE FALSE END
    SQL

    remove_column :nodes, :node_type, :integer
    rename_column :nodes, :legacy_node_type, :node_type
    add_index :nodes, :node_type
  end
end
