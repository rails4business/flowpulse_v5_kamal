class AddActualTimesToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :actual_started_at, :datetime
    add_column :data_commitments, :actual_ended_at, :datetime
    add_index :data_commitments, :actual_started_at
  end
end
