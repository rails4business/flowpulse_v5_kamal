class CreateImpegnoContactsAndPlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :impegno_contacts do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false, default: "person"
      t.string :email
      t.string :phone
      t.text :notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :impegno_contacts, %i[profile_id name]

    create_table :impegno_places do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false, default: "other"
      t.string :address
      t.string :online_url
      t.text :notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :impegno_places, %i[profile_id name]
  end
end
