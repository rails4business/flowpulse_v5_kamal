class AddBrandScopedAuthentication < ActiveRecord::Migration[8.1]
  def up
    add_reference :sessions, :brand_access, foreign_key: true
    add_column :sessions, :authenticated_at, :datetime
    add_column :sessions, :expires_at, :datetime
    add_column :sessions, :revoked_at, :datetime
    add_column :sessions, :authentication_method, :string, null: false, default: "password"
    add_index :sessions, :expires_at
    add_index :sessions, :revoked_at

    execute <<~SQL.squish
      UPDATE sessions
      SET authenticated_at = created_at,
          expires_at = created_at + INTERVAL '60 days'
    SQL
    change_column_null :sessions, :authenticated_at, false
    change_column_null :sessions, :expires_at, false

    add_column :users, :email_verified_at, :datetime
    add_column :users, :registration_status, :string, null: false, default: "active"
    execute "UPDATE users SET email_verified_at = created_at WHERE email_verified_at IS NULL"
    add_index :users, :registration_status

    create_table :email_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :brand_node, foreign_key: { to_table: :nodes }
      t.references :requested_domain, foreign_key: { to_table: :domains }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :verified_at
      t.string :return_to
      t.string :request_ip
      t.string :user_agent
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :email_verifications, :token_digest, unique: true
    add_index :email_verifications, %i[user_id verified_at]
  end

  def down
    drop_table :email_verifications

    remove_index :users, :registration_status
    remove_column :users, :registration_status
    remove_column :users, :email_verified_at

    remove_index :sessions, :revoked_at
    remove_index :sessions, :expires_at
    remove_column :sessions, :authentication_method
    remove_column :sessions, :revoked_at
    remove_column :sessions, :expires_at
    remove_column :sessions, :authenticated_at
    remove_reference :sessions, :brand_access, foreign_key: true
  end
end
