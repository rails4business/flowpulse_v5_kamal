class RemoveDomainAccesses < ActiveRecord::Migration[8.1]
  def up
    drop_table :domain_accesses
    add_index :domains, :node_id,
      unique: true,
      where: '"primary" = TRUE AND canonical_host IS NULL',
      name: "index_one_primary_domain_per_brand"
  end

  def down
    remove_index :domains, name: "index_one_primary_domain_per_brand"
    create_table :domain_accesses do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.references :brand_access, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :activated_at, null: false
      t.datetime :last_accessed_at, null: false
      t.timestamps
    end
    add_index :domain_accesses, %i[profile_id domain_id], unique: true
    add_index :domain_accesses, %i[brand_access_id domain_id], unique: true
    add_index :domain_accesses, :status
  end
end
