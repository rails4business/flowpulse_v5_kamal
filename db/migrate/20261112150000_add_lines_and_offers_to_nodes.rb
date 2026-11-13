class AddLinesAndOffersToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :line_slugs, :string, array: true, default: [], null: false
    add_column :nodes, :offer_slugs, :string, array: true, default: [], null: false

    add_index :nodes, :line_slugs, using: :gin
    add_index :nodes, :offer_slugs, using: :gin

    create_table :metro_lines do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :start_node, null: false, foreign_key: { to_table: :nodes }
      t.references :end_node, null: false, foreign_key: { to_table: :nodes }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end
    add_index :metro_lines, :slug, unique: true

    create_table :offers do |t|
      t.references :metro_line, null: false, foreign_key: true
      t.references :start_node, null: false, foreign_key: { to_table: :nodes }
      t.references :end_node, null: false, foreign_key: { to_table: :nodes }
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.string :previous_purchase_mode, null: false, default: "none"
      t.string :included_offer_slugs, array: true, default: [], null: false
      t.jsonb :settings, null: false, default: {}
      t.timestamps
    end
    add_index :offers, :slug, unique: true
    add_index :offers, :included_offer_slugs, using: :gin
  end
end
