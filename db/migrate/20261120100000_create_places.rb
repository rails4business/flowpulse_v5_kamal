# Luoghi fisici (piano contenuti, punto 12): nascono dall'admin, valgono per uno o più domini e in ogni dominio
# possono avere un Content che li racconta.
class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :places do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :address
      t.string :city
      t.string :province
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :status, null: false, default: "open"
      t.date :closed_on
      t.text :description
      t.references :created_by_profile, foreign_key: { to_table: :profiles }
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :places, :slug, unique: true
    add_index :places, :status

    create_table :place_domains do |t|
      t.references :place, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.references :content, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :place_domains, [ :place_id, :domain_id ], unique: true
  end
end
