class AddControllerActionToDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :controller_action, :string
  end
end
