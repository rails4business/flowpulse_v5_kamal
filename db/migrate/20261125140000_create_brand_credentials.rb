class CreateBrandCredentials < ActiveRecord::Migration[8.1]
  def up
    create_table :brand_credentials do |t|
      t.references :brand_access, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :brand_node, null: false, foreign_key: { to_table: :nodes }
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :status, null: false, default: "active"
      t.datetime :email_verified_at
      t.datetime :last_authenticated_at
      t.timestamps
    end

    add_index :brand_credentials, :brand_access_id, unique: true
    add_index :brand_credentials, %i[brand_node_id email_address], unique: true
    add_index :brand_credentials, :status

    add_reference :sessions, :brand_credential, foreign_key: { on_delete: :nullify }, index: true

    execute <<~SQL.squish
      INSERT INTO brand_credentials
        (brand_access_id, brand_node_id, email_address, password_digest, status, email_verified_at, created_at, updated_at)
      SELECT
        accesses.id,
        accesses.brand_node_id,
        LOWER(TRIM(users.email_address)),
        users.password_digest,
        CASE
          WHEN accesses.status <> 'active' THEN 'revoked'
          WHEN users.email_verified_at IS NULL THEN 'pending_verification'
          ELSE 'active'
        END,
        users.email_verified_at,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM brand_accesses accesses
      INNER JOIN profiles ON profiles.id = accesses.profile_id
      INNER JOIN users ON users.id = profiles.user_id
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    remove_reference :sessions, :brand_credential, foreign_key: true
    drop_table :brand_credentials
  end
end
