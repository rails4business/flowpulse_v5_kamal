class AddResolvedAtToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :resolved_at, :datetime
    add_index :data_commitments, :resolved_at
  end
end
