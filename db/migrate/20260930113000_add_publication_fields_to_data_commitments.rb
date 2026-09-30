class AddPublicationFieldsToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_column :data_commitments, :content_key, :string
    add_column :data_commitments, :publish_on_completion, :boolean, default: false, null: false
    add_column :data_commitments, :publication_status, :string, default: "draft", null: false
    add_column :data_commitments, :publication_visibility, :string, default: "private", null: false
    add_column :data_commitments, :published_at, :datetime
    add_reference :data_commitments, :published_by_profile, foreign_key: { to_table: :profiles }

    add_index :data_commitments, [:domain_id, :content_key]
    add_index :data_commitments, :publication_status
  end
end
