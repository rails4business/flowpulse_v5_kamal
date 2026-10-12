class CreateSkillProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_products do |t|
      t.references :reusable_skill_node, null: false, foreign_key: true
      t.references :created_by_profile, null: false, foreign_key: { to_table: :profiles }
      t.string :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "private"
      t.string :format, null: false, default: "markdown"
      t.text :body
      t.jsonb :data, null: false, default: {}
      t.string :source_path
      t.datetime :published_at
      t.timestamps
    end

    add_index :skill_products,
      %i[reusable_skill_node_id slug],
      unique: true,
      name: "index_skill_products_on_activation_and_slug"
    add_index :skill_products,
      :source_path,
      unique: true,
      where: "source_path IS NOT NULL"

    create_table :skill_product_links do |t|
      t.references :source_product, null: false, foreign_key: { to_table: :skill_products }
      t.references :target_product, null: false, foreign_key: { to_table: :skill_products }
      t.string :relation_kind, null: false, default: "uses"
      t.integer :position
      t.timestamps
    end

    add_index :skill_product_links,
      %i[source_product_id target_product_id relation_kind],
      unique: true,
      name: "index_skill_product_links_uniqueness"
  end
end
