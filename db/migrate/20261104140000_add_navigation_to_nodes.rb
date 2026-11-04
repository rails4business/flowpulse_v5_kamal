class AddNavigationToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :navigation, :jsonb
  end
end
