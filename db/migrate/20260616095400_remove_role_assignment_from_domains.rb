class RemoveRoleAssignmentFromDomains < ActiveRecord::Migration[8.1]
  def change
    remove_reference :domains, :role_assignment, foreign_key: { to_table: :role_assignments }, type: :bigint
  end
end
