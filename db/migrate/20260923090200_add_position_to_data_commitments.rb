class AddPositionToDataCommitments < ActiveRecord::Migration[8.1]
  def up
    add_column :data_commitments, :position, :integer, null: false, default: 0
    add_index :data_commitments, %i[data_experience_id position]
    add_index :data_commitments, %i[data_session_id position]
    add_index :data_commitments, %i[data_slot_id position]

    execute <<~SQL.squish
      WITH ranked AS (
        SELECT id,
               ROW_NUMBER() OVER (
                 PARTITION BY data_experience_id, data_session_id, data_slot_id
                 ORDER BY starts_at ASC NULLS LAST, created_at ASC, id ASC
               ) AS new_position
        FROM data_commitments
        WHERE data_experience_id IS NOT NULL
      )
      UPDATE data_commitments
      SET position = ranked.new_position
      FROM ranked
      WHERE data_commitments.id = ranked.id
    SQL
  end

  def down
    remove_index :data_commitments, %i[data_slot_id position]
    remove_index :data_commitments, %i[data_session_id position]
    remove_index :data_commitments, %i[data_experience_id position]
    remove_column :data_commitments, :position
  end
end
