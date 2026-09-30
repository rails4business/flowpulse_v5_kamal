class AddAccessModesToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :access_modes, :string, array: true, default: [], null: false
    add_index :data_commitments, :access_modes, using: :gin
  end
end
