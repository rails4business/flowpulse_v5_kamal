class PrepareContextualRoleManagement < ActiveRecord::Migration[8.1]
  def up
    add_reference :nodes,
      :responsible_profile,
      foreign_key: { to_table: :profiles },
      index: true,
      null: true

    add_reference :role_assignments,
      :brand_access,
      foreign_key: true,
      index: true,
      null: true
    add_reference :role_assignments,
      :assigned_by_profile,
      foreign_key: { to_table: :profiles },
      index: true,
      null: true
    add_column :role_assignments, :status, :string, default: "active", null: false
    add_column :role_assignments, :starts_at, :datetime
    add_column :role_assignments, :ends_at, :datetime
    add_index :role_assignments, :status

    execute <<~SQL.squish
      UPDATE role_assignments
      SET role_operator = 'imprenditore_generaimpresa'
      WHERE role_operator = 'creator_generaimpresa'
    SQL

    execute <<~SQL.squish
      UPDATE role_assignments AS assignments
      SET brand_access_id = accesses.id
      FROM brand_accesses AS accesses
      WHERE assignments.role = 11
        AND assignments.context_type = 'Node'
        AND accesses.profile_id = assignments.profile_id
        AND accesses.brand_node_id = assignments.context_id
        AND accesses.status = 'active'
        AND assignments.brand_access_id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE users
      SET active_role = 0
      WHERE active_role = 1
        AND superadmin = FALSE
        AND current_role_assignment_id IS NULL
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE role_assignments
      SET role_operator = 'creator_generaimpresa'
      WHERE role_operator = 'imprenditore_generaimpresa'
    SQL

    remove_index :role_assignments, :status
    remove_column :role_assignments, :ends_at
    remove_column :role_assignments, :starts_at
    remove_column :role_assignments, :status
    remove_reference :role_assignments, :assigned_by_profile, foreign_key: { to_table: :profiles }
    remove_reference :role_assignments, :brand_access, foreign_key: true
    remove_reference :nodes, :responsible_profile, foreign_key: { to_table: :profiles }
  end
end
