class CreateBrandAccessGrants < ActiveRecord::Migration[8.1]
  def change
    add_column :brand_accesses, :grant_managed, :boolean, default: false, null: false

    create_table :brand_access_grants do |t|
      t.references :brand_access, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true
      t.references :brand_request, null: true, foreign_key: true
      t.references :granted_by_profile, null: true, foreign_key: { to_table: :profiles }
      t.string :status, null: false, default: "active"
      t.datetime :granted_at, null: false
      t.datetime :revoked_at
      t.timestamps

      t.index %i[brand_access_id node_id], unique: true
      t.index :status
    end
  end
end
