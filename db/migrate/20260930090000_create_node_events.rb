class CreateNodeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :node_events do |t|
      t.references :node, null: false, foreign_key: true
      t.references :performed_by_user, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.text :note
      t.datetime :happened_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end

    add_index :node_events, %i[node_id happened_at]
  end
end
