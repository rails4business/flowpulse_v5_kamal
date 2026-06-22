class RestructureRolesAndChannels < ActiveRecord::Migration[8.1]
  def change
    add_reference :role_assignments, :parent, foreign_key: { to_table: :role_assignments }, type: :bigint
    add_reference :users, :current_role_assignment, foreign_key: { to_table: :role_assignments }, type: :bigint
    remove_column :users, :demo_access, :boolean
  end
end
