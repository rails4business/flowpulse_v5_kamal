class AddCurrentRoleAssignmentToBrandAccesses < ActiveRecord::Migration[8.1]
  def change
    add_reference :brand_accesses,
      :current_role_assignment,
      foreign_key: { to_table: :role_assignments, on_delete: :nullify },
      index: true
  end
end
