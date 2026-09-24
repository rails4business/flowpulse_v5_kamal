class ExpandExperienceTreeContext < ActiveRecord::Migration[8.1]
  def up
    add_reference :data_slots, :data_experience, foreign_key: true
    add_column :data_slots, :starts_at, :datetime
    add_column :data_slots, :ends_at, :datetime

    execute <<~SQL.squish
      UPDATE data_slots
      SET data_experience_id = data_sessions.data_experience_id
      FROM data_sessions
      WHERE data_slots.data_session_id = data_sessions.id
    SQL

    change_column_null :data_slots, :data_experience_id, false
    change_column_null :data_slots, :data_session_id, true
    add_index :data_slots, %i[data_experience_id starts_at]

    add_reference :data_commitments, :data_experience, foreign_key: true
    add_reference :data_commitments, :data_session, foreign_key: true

    execute <<~SQL.squish
      UPDATE data_commitments
      SET data_session_id = data_slots.data_session_id,
          data_experience_id = data_slots.data_experience_id
      FROM data_slots
      WHERE data_commitments.data_slot_id = data_slots.id
    SQL

    add_index :data_commitments, %i[data_experience_id starts_at]
    add_index :data_commitments, %i[data_session_id starts_at]
  end

  def down
    remove_index :data_commitments, column: %i[data_session_id starts_at]
    remove_index :data_commitments, column: %i[data_experience_id starts_at]
    remove_reference :data_commitments, :data_session, foreign_key: true
    remove_reference :data_commitments, :data_experience, foreign_key: true
    remove_index :data_slots, column: %i[data_experience_id starts_at]
    change_column_null :data_slots, :data_session_id, false
    remove_column :data_slots, :ends_at
    remove_column :data_slots, :starts_at
    remove_reference :data_slots, :data_experience, foreign_key: true
  end
end
