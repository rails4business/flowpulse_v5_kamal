class RemoveDuplicateProfessionalCalendarIndexes < ActiveRecord::Migration[8.1]
  def up
    remove_index :data_sessions, name: "index_data_sessions_on_professional_calendar_id", if_exists: true
    remove_index :data_sessions, name: "index_data_sessions_on_professional_calendar_id_and_starts_at", if_exists: true
  end

  def down
    add_index :data_sessions, :professional_calendar_id,
      name: "index_data_sessions_on_professional_calendar_id",
      if_not_exists: true
    add_index :data_sessions, [:professional_calendar_id, :starts_at],
      name: "index_data_sessions_on_professional_calendar_id_and_starts_at",
      if_not_exists: true
  end
end
