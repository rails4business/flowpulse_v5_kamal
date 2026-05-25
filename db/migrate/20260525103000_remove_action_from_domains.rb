class RemoveActionFromDomains < ActiveRecord::Migration[8.1]
  def change
    remove_column :domains, :action, :string, default: "mvp_home", null: false
  end
end
