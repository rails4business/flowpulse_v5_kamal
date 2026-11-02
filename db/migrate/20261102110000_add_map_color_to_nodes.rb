class AddMapColorToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :map_color, :string
  end
end
