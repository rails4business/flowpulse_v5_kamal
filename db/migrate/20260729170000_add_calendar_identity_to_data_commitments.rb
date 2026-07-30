class AddCalendarIdentityToDataCommitments < ActiveRecord::Migration[8.1]
  def up
    add_column :data_commitments, :calendar_key, :string
    add_column :data_commitments, :calendar_label, :string
    add_column :data_commitments, :blocks_calendar, :boolean, null: false, default: true
    add_reference :data_commitments, :assignee_profile, foreign_key: { to_table: :profiles }
    add_reference :data_commitments, :responsible_profile, foreign_key: { to_table: :profiles }

    execute <<~SQL.squish
      UPDATE data_commitments
      SET calendar_key = 'profile:' || profile_id,
          calendar_label = COALESCE(
            (SELECT NULLIF(profiles.display_name, '') FROM profiles WHERE profiles.id = data_commitments.profile_id),
            (SELECT profiles.username FROM profiles WHERE profiles.id = data_commitments.profile_id),
            'Profilo ' || profile_id
          ),
          assignee_profile_id = profile_id
    SQL

    change_column_null :data_commitments, :calendar_key, false
    change_column_null :data_commitments, :calendar_label, false
    add_index :data_commitments, %i[profile_id calendar_key starts_at], name: "index_commitments_on_owner_calendar_start"
    add_index :data_commitments, %i[profile_id calendar_key], unique: true, where: "status = 'in_progress' AND actual_ended_at IS NULL", name: "index_one_active_timer_per_calendar"
  end

  def down
    remove_index :data_commitments, name: "index_one_active_timer_per_calendar"
    remove_index :data_commitments, name: "index_commitments_on_owner_calendar_start"
    remove_reference :data_commitments, :responsible_profile, foreign_key: { to_table: :profiles }
    remove_reference :data_commitments, :assignee_profile, foreign_key: { to_table: :profiles }
    remove_column :data_commitments, :blocks_calendar
    remove_column :data_commitments, :calendar_label
    remove_column :data_commitments, :calendar_key
  end
end
