class AddSyncKeyToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :sync_key, :uuid, default: -> { "gen_random_uuid()" }, null: false
    add_index :data_commitments, :sync_key, unique: true
  end
end
