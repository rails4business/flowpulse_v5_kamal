class CreateBrandActivitiesAndProcesses < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_activities do |t|
      t.references :node, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :slug, null: false
      t.string :title, null: false
      t.string :short_label
      t.text :description
      t.string :color, null: false, default: "slate"
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :brand_activities, :slug, unique: true
    add_index :brand_activities, [:node_id, :title]

    create_table :brand_processes do |t|
      t.references :node, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
    add_index :brand_processes, [:node_id, :slug], unique: true
    add_index :brand_processes, [:node_id, :status]

    add_reference :data_experiences, :brand_process, foreign_key: true
    add_reference :data_sessions, :brand_activity, foreign_key: true
    add_reference :data_sessions, :professional_node, foreign_key: { to_table: :nodes }
    add_column :data_sessions, :visibility, :string, null: false, default: "private"
    add_index :data_sessions, [:professional_node_id, :starts_at], name: "index_data_sessions_on_professional_calendar"
    add_index :data_sessions, [:brand_activity_id, :starts_at]
  end
end
