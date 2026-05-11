class AddDemoAccessToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :demo_access, :boolean
  end
end
