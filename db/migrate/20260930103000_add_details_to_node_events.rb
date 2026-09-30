class AddDetailsToNodeEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :node_events, :public_id, :string
    add_column :node_events, :title, :string
    add_column :node_events, :body_md, :text
    add_column :node_events, :development_entry_slug, :string

    reversible do |direction|
      direction.up do
        execute "UPDATE node_events SET public_id = gen_random_uuid()::text WHERE public_id IS NULL"
        change_column_null :node_events, :public_id, false
      end
    end

    add_index :node_events, :public_id, unique: true
    add_index :node_events, :development_entry_slug
  end
end
