class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false
      t.string :context_type
      t.bigint :context_id

      t.timestamps
    end

    add_index :role_assignments, :role
    add_index :role_assignments, [ :context_type, :context_id ]
    add_index :role_assignments,
      [ :user_id, :role ],
      unique: true,
      where: "context_type IS NULL AND context_id IS NULL",
      name: "index_role_assignments_on_global_role"
    add_index :role_assignments,
      [ :user_id, :role, :context_type, :context_id ],
      unique: true,
      where: "context_type IS NOT NULL AND context_id IS NOT NULL",
      name: "index_role_assignments_on_context_role"
    add_check_constraint :role_assignments,
      "(context_type IS NULL AND context_id IS NULL) OR (context_type IS NOT NULL AND context_id IS NOT NULL)",
      name: "role_assignments_context_presence"
  end
end
