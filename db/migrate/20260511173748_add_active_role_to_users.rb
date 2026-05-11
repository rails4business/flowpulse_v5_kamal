class AddActiveRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :active_role, :integer, default: 0, null: false
  end
end
