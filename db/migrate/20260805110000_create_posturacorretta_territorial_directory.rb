class CreatePosturacorrettaTerritorialDirectory < ActiveRecord::Migration[8.1]
  def change
    create_table :posturacorretta_directory_people do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :profile, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :role
      t.string :city
      t.text :summary
      t.string :visibility, null: false, default: "draft"
      t.jsonb :listing_sections, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :posturacorretta_directory_people, %i[domain_id slug], unique: true

    create_table :posturacorretta_directory_places do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :kind, null: false, default: "other"
      t.string :city
      t.string :address
      t.text :summary
      t.string :visibility, null: false, default: "draft"
      t.jsonb :listing_sections, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :posturacorretta_directory_places, %i[domain_id slug], unique: true

    create_table :posturacorretta_territorial_paths do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :responsible_person, null: false, foreign_key: { to_table: :posturacorretta_directory_people }
      t.references :place, foreign_key: { to_table: :posturacorretta_directory_places }
      t.string :title, null: false
      t.string :slug, null: false
      t.string :city
      t.text :summary
      t.string :status, null: false, default: "draft"
      t.jsonb :programs, null: false, default: []
      t.jsonb :listing_sections, null: false, default: ["percorso"]
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :posturacorretta_territorial_paths, %i[domain_id slug], unique: true

    create_table :posturacorretta_territorial_path_participants do |t|
      t.references :territorial_path, null: false, foreign_key: { to_table: :posturacorretta_territorial_paths }
      t.references :person, null: false, foreign_key: { to_table: :posturacorretta_directory_people }
      t.string :role, null: false, default: "professional"
      t.timestamps
    end
    add_index :posturacorretta_territorial_path_participants, %i[territorial_path_id person_id], unique: true, name: "index_territorial_path_participants_on_path_and_person"
  end
end
