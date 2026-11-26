class AddAuditLogToRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :role_assignments, :audit_log, :jsonb, default: [], null: false
  end
end
