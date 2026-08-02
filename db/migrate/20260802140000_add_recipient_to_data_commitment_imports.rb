class AddRecipientToDataCommitmentImports < ActiveRecord::Migration[8.1]
  def change
    add_reference :data_commitment_imports, :target_profile, foreign_key: { to_table: :profiles }
    add_column :data_commitment_imports, :source_type, :string, null: false, default: "manual"
    add_column :data_commitment_imports, :source_fingerprint, :string
    add_index :data_commitment_imports, :source_fingerprint, unique: true
  end
end
