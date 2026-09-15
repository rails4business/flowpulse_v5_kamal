class AddOperatorRolesToBrands < ActiveRecord::Migration[8.1]
  def up
    add_column :nodes, :operator_roles, :jsonb, null: false, default: []
    add_column :role_assignments, :role_operator, :string

    remove_index :role_assignments, name: "index_role_assignments_on_context_role"
    add_index :role_assignments,
      [ :profile_id, :role, :context_type, :context_id ],
      unique: true,
      where: "context_type IS NOT NULL AND context_id IS NOT NULL AND role <> 11",
      name: "index_role_assignments_on_context_role"
    add_index :role_assignments,
      [ :profile_id, :role, :role_operator, :context_type, :context_id ],
      unique: true,
      where: "context_type IS NOT NULL AND context_id IS NOT NULL AND role = 11",
      name: "index_role_assignments_on_operator_function"

    execute <<~SQL.squish
      UPDATE nodes
      SET operator_roles = source.operator_roles
      FROM (
        SELECT DISTINCT ON (node_id)
          node_id,
          settings::jsonb -> 'operational_roles' AS operator_roles
        FROM domains
        WHERE node_id IS NOT NULL
          AND settings::jsonb ? 'operational_roles'
        ORDER BY node_id, "primary" DESC, id ASC
      ) AS source
      WHERE nodes.id = source.node_id
    SQL
  end

  def down
    remove_index :role_assignments, name: "index_role_assignments_on_operator_function"
    remove_index :role_assignments, name: "index_role_assignments_on_context_role"
    add_index :role_assignments,
      [ :profile_id, :role, :context_type, :context_id ],
      unique: true,
      where: "context_type IS NOT NULL AND context_id IS NOT NULL",
      name: "index_role_assignments_on_context_role"

    remove_column :role_assignments, :role_operator
    remove_column :nodes, :operator_roles
  end
end
