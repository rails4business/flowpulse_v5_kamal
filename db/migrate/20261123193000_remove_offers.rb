class RemoveOffers < ActiveRecord::Migration[8.1]
  def up
    drop_table :offers
    remove_column :nodes, :offer_slugs
  end

  def down
    add_column :nodes, :offer_slugs, :string, array: true, default: [], null: false
    add_index :nodes, :offer_slugs, using: :gin

    create_table :offers do |t|
      t.references :metro_line, foreign_key: true
      t.references :line_node, foreign_key: { to_table: :nodes }
      t.references :start_node, null: false, foreign_key: { to_table: :nodes }
      t.references :end_node, null: false, foreign_key: { to_table: :nodes }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.string :previous_purchase_mode, null: false, default: "none"
      t.string :included_offer_slugs, array: true, default: [], null: false
      t.decimal :discount_percent, precision: 5, scale: 2
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end
    add_index :offers, :slug, unique: true
    add_index :offers, :included_offer_slugs, using: :gin
  end
end
