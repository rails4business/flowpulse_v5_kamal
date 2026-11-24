class AddNavigationLabelToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :navigation_label, :string
  end
end
