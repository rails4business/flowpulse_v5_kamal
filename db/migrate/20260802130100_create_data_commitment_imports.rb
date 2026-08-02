class CreateDataCommitmentImports < ActiveRecord::Migration[8.1]
  def change
    create_table :data_commitment_imports do |t|
      t.references :uploaded_by_user, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.string :source_name, null: false
      t.jsonb :payload, null: false, default: {}
      t.jsonb :summary, null: false, default: {}
      t.datetime :applied_at
      t.timestamps
    end
  end
end
