class AddRoleAssignmentToDomains < ActiveRecord::Migration[8.1]
  def up
    add_reference :domains, :role_assignment, foreign_key: { to_table: :role_assignments }, type: :bigint

    execute <<~SQL.squish
      UPDATE domains
      SET role_assignment_id = nodes.role_assignment_id
      FROM nodes
      WHERE domains.node_id = nodes.id
    SQL
  end

  def down
    remove_reference :domains, :role_assignment, foreign_key: { to_table: :role_assignments }, type: :bigint
  end
end
