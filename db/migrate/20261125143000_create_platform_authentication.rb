class CreatePlatformAuthentication < ActiveRecord::Migration[8.1]
  def up
    create_table :platform_credentials do |t|
      t.references :profile, null: false, foreign_key: true, index: { unique: true }
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :status, null: false, default: "active"
      t.datetime :email_verified_at
      t.datetime :last_authenticated_at
      t.timestamps
    end
    add_index :platform_credentials, :email_address, unique: true
    add_index :platform_credentials, :status

    create_table :system_role_assignments do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :assigned_by_profile, null: true, foreign_key: { to_table: :profiles }
      t.string :role_code, null: false
      t.string :status, null: false, default: "active"
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end
    add_index :system_role_assignments, %i[profile_id role_code], unique: true
    add_index :system_role_assignments, %i[role_code status]

    add_reference :sessions, :profile, null: true, foreign_key: true, index: true
    add_reference :sessions, :platform_credential, null: true,
      foreign_key: { on_delete: :nullify }, index: true

    execute <<~SQL.squish
      INSERT INTO platform_credentials
        (profile_id, email_address, password_digest, status, email_verified_at, created_at, updated_at)
      SELECT
        profiles.id,
        LOWER(TRIM(users.email_address)),
        users.password_digest,
        CASE WHEN users.registration_status = 'active' THEN 'active' ELSE 'suspended' END,
        users.email_verified_at,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM users
      INNER JOIN profiles ON profiles.user_id = users.id
      WHERE users.superadmin = TRUE
      ON CONFLICT DO NOTHING
    SQL

    execute <<~SQL.squish
      INSERT INTO system_role_assignments
        (profile_id, role_code, status, created_at, updated_at)
      SELECT
        profiles.id,
        'superadmin',
        CASE WHEN users.registration_status = 'active' THEN 'active' ELSE 'suspended' END,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM users
      INNER JOIN profiles ON profiles.user_id = users.id
      WHERE users.superadmin = TRUE
      ON CONFLICT DO NOTHING
    SQL

    execute <<~SQL.squish
      UPDATE sessions
      SET profile_id = profiles.id
      FROM profiles
      WHERE profiles.user_id = sessions.user_id
        AND sessions.profile_id IS NULL
    SQL
  end

  def down
    remove_reference :sessions, :platform_credential, foreign_key: true
    remove_reference :sessions, :profile, foreign_key: true
    drop_table :system_role_assignments
    drop_table :platform_credentials
  end
end
