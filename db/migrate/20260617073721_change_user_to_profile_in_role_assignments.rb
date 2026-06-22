class ChangeUserToProfileInRoleAssignments < ActiveRecord::Migration[8.1]
  def up
    # 1. Remove old foreign key and unique indexes referencing user_id
    remove_foreign_key :role_assignments, :users
    remove_index :role_assignments, name: "index_role_assignments_on_context_role"
    remove_index :role_assignments, name: "index_role_assignments_on_global_role"
    remove_index :role_assignments, name: "index_role_assignments_on_user_id"

    # 2. Add profile_id column (initially nullable to migrate data)
    add_reference :role_assignments, :profile, foreign_key: true, index: true

    # 3. Migrate data: Map user_id to profile_id, creating profile if missing
    execute <<-SQL.squish
      SELECT id, user_id FROM role_assignments
    SQL
    
    # We do data migration using ActiveRecord models temporarily
    # but to prevent model class loading issues, we use native SQL or raw DB connections.
    RoleAssignment.reset_column_information if defined?(RoleAssignment)
    
    # Ensure every user with a role assignment has a profile
    User.all.each do |user|
      if user.role_assignments.any? && user.profile.nil?
        user.create_profile!(display_name: user.email_address.split('@').first)
      end
    end

    # Populate profile_id in role_assignments
    execute <<-SQL.squish
      UPDATE role_assignments
      SET profile_id = (SELECT id FROM profiles WHERE profiles.user_id = role_assignments.user_id)
    SQL

    # 4. Make profile_id NOT NULL
    change_column_null :role_assignments, :profile_id, false

    # 5. Remove user_id column
    remove_column :role_assignments, :user_id

    # 6. Add the new unique indexes using profile_id
    add_index :role_assignments, [:profile_id, :role, :context_type, :context_id], 
              unique: true, 
              name: "index_role_assignments_on_context_role", 
              where: "((context_type IS NOT NULL) AND (context_id IS NOT NULL))"
              
    add_index :role_assignments, [:profile_id, :role], 
              unique: true, 
              name: "index_role_assignments_on_global_role", 
              where: "((context_type IS NULL) AND (context_id IS NULL))"
  end

  def down
    remove_index :role_assignments, name: "index_role_assignments_on_context_role"
    remove_index :role_assignments, name: "index_role_assignments_on_global_role"
    remove_reference :role_assignments, :profile, foreign_key: true

    add_reference :role_assignments, :user, foreign_key: true, index: true

    execute <<-SQL.squish
      UPDATE role_assignments
      SET user_id = (SELECT user_id FROM profiles WHERE profiles.id = role_assignments.profile_id)
    SQL

    change_column_null :role_assignments, :user_id, false

    remove_column :role_assignments, :profile_id

    add_index :role_assignments, [:user_id, :role, :context_type, :context_id], 
              unique: true, 
              name: "index_role_assignments_on_context_role", 
              where: "((context_type IS NOT NULL) AND (context_id IS NOT NULL))"
              
    add_index :role_assignments, [:user_id, :role], 
              unique: true, 
              name: "index_role_assignments_on_global_role", 
              where: "((context_type IS NULL) AND (context_id IS NULL))"
  end
end
