class RemoveDataEvents < ActiveRecord::Migration[8.1]
  def change
    remove_reference :data_commitments, :requested_data_event, foreign_key: { to_table: :data_events }
    remove_reference :data_commitments, :data_event, foreign_key: true
    drop_table :data_events
  end
end
