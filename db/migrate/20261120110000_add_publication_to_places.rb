# Pubblicazione del luogo, separata da aperto/chiuso: si modifica dall'admin dei luoghi, come per i Content.
class AddPublicationToPlaces < ActiveRecord::Migration[8.1]
  def change
    add_column :places, :publication_status, :string, null: false, default: "draft"
    add_column :places, :publication_visibility, :string, null: false, default: "private"
    add_column :places, :published_at, :datetime
    add_index :places, :publication_status
  end
end
