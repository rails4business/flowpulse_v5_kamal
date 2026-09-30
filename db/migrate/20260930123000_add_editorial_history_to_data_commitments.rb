class AddEditorialHistoryToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :publication_change_kind, :string
    add_column :data_commitments, :publication_note_md, :text
    add_reference :data_commitments, :previous_publication_commitment,
      foreign_key: { to_table: :data_commitments }

    add_index :data_commitments,
      [:domain_id, :content_key, :status],
      name: "index_commitments_on_editorial_history"
  end
end
