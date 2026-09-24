class SeparateProfessionalCalendarsFromBrandActivities < ActiveRecord::Migration[8.1]
  def change
    rename_table :brand_activities, :professional_calendars
    rename_column :professional_calendars, :node_id, :brand_node_id
    rename_column :data_sessions, :brand_activity_id, :professional_calendar_id

    remove_index :data_sessions, name: "index_data_sessions_on_professional_calendar", if_exists: true
    remove_reference :data_sessions, :professional_node, foreign_key: { to_table: :nodes }

    add_reference :professional_calendars, :professional_node, foreign_key: { to_table: :nodes }
    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE professional_calendars
          SET professional_node_id = COALESCE(nodes.professional_owner_node_id,
            CASE WHEN nodes.professional = TRUE THEN nodes.id END)
          FROM nodes
          WHERE nodes.id = professional_calendars.brand_node_id
        SQL
      end
    end

    add_index :professional_calendars, [:professional_node_id, :active], name: "index_professional_calendars_on_owner_and_active"
    add_index :data_sessions, [:professional_calendar_id, :starts_at], name: "index_data_sessions_on_calendar_and_start"

    create_table :brand_activities do |t|
      t.references :node, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :brand_activities, [:node_id, :slug], unique: true
    add_index :brand_activities, [:node_id, :title]
    add_reference :data_sessions, :brand_activity, foreign_key: false
    add_foreign_key :data_sessions, :brand_activities, name: "fk_data_sessions_brand_activity"
  end
end
