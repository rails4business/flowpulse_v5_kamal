class IntegrateFlowTreeIntoFlowpulse < ActiveRecord::Migration[8.1]
  def change
    # 1. Create nodes table
    create_table :nodes do |t|
      t.string :title
      t.string :slug
      t.bigint :parent_id
      t.integer :position
      t.string :node_type, default: "node", null: false
      t.bigint :link_node_id
      t.string :visibility, default: "public", null: false
      t.string :status, default: "draft", null: false
      t.string :view_type, default: "default", null: false
      t.text :description
      t.integer :depth
      t.string :content_type
      t.bigint :role_assignment_id, null: false

      t.timestamps
    end

    add_index :nodes, :parent_id
    add_index :nodes, :role_assignment_id
    add_index :nodes, :node_type
    add_index :nodes, :link_node_id
    add_index :nodes, :status
    add_index :nodes, :view_type
    add_index :nodes, :visibility

    # Add foreign keys for nodes self-referential relations
    add_foreign_key :nodes, :nodes, column: :parent_id
    add_foreign_key :nodes, :nodes, column: :link_node_id
    add_foreign_key :nodes, :role_assignments, column: :role_assignment_id

    # 2. Create node_hierarchies table for closure_tree
    create_table :node_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end

    add_index :node_hierarchies, [:ancestor_id, :descendant_id, :generations], unique: true, name: "node_anc_desc_idx"
    add_index :node_hierarchies, [:descendant_id], name: "node_desc_idx"

    # 3. Create node_contents table
    create_table :node_contents do |t|
      t.bigint :node_id, null: false
      t.text :body_html
      t.jsonb :body_json, default: {}, null: false
      t.text :body_md
      t.jsonb :data, default: {}, null: false
      t.string :editor, default: "markdown", null: false
      t.string :format, default: "markdown", null: false
      t.string :source_checksum
      t.string :source_path

      t.timestamps
    end

    add_index :node_contents, :node_id, unique: true
    add_index :node_contents, :editor
    add_index :node_contents, :format
    add_index :node_contents, :source_checksum

    add_foreign_key :node_contents, :nodes, column: :node_id

    # 4. Modify existing domains table in flowpulse_v_5
    add_reference :domains, :node, foreign_key: { to_table: :nodes }, null: true
    add_reference :domains, :role_assignment, foreign_key: { to_table: :role_assignments }, null: true
  end
end
