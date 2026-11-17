class CreateContents < ActiveRecord::Migration[8.1]
  def change
    create_table :contents do |t|
      t.references :node, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :contents }
      t.string :key, null: false
      t.string :slug, null: false
      t.string :format, null: false
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.text :description
      t.text :body_md
      t.string :source_path
      t.string :source_checksum
      t.jsonb :data, null: false, default: {}
      t.date :written_on
      t.datetime :revised_at
      t.string :publication_status, null: false, default: "draft"
      t.string :publication_visibility, null: false, default: "private"
      t.string :access_modes, array: true, null: false, default: []
      t.datetime :published_at
      t.timestamps
    end
    add_index :contents, :key, unique: true
    add_index :contents, [:node_id, :parent_id, :slug], unique: true, nulls_not_distinct: true
    add_index :contents, :format
    add_index :contents, :publication_status

    create_table :content_publications do |t|
      t.references :content, null: false, foreign_key: true
      t.string :key, null: false
      t.string :platform, null: false
      t.string :format, null: false
      t.string :url
      t.string :external_id
      t.string :title
      t.text :body
      t.integer :position, null: false, default: 0
      t.datetime :scheduled_at
      t.jsonb :metadata, null: false, default: {}
      t.string :publication_status, null: false, default: "draft"
      t.string :publication_visibility, null: false, default: "private"
      t.datetime :published_at
      t.timestamps
    end
    add_index :content_publications, [:content_id, :key], unique: true
    add_index :content_publications, [:platform, :external_id]

    create_table :content_contributions do |t|
      t.references :content, null: false, foreign_key: true
      t.references :profile, foreign_key: true
      t.references :contact, foreign_key: { to_table: :impegno_contacts }
      t.string :role, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :content_contributions, [:content_id, :role, :profile_id], unique: true, where: "profile_id IS NOT NULL",
              name: "index_content_contributions_on_profile_role"
    add_index :content_contributions, [:content_id, :role, :contact_id], unique: true, where: "contact_id IS NOT NULL",
              name: "index_content_contributions_on_contact_role"
    add_check_constraint :content_contributions, "num_nonnulls(profile_id, contact_id) = 1",
                         name: "content_contributions_one_contributor"

    create_table :content_links do |t|
      t.references :source_content, foreign_key: { to_table: :contents }
      t.references :source_node, foreign_key: { to_table: :nodes }
      t.references :target_content, null: false, foreign_key: { to_table: :contents }
      t.string :kind, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :content_links, "num_nonnulls(source_content_id, source_node_id) = 1",
                         name: "content_links_one_source"

    add_reference :data_commitments, :content, foreign_key: true
    add_reference :data_commitments, :content_publication, foreign_key: true
  end
end
