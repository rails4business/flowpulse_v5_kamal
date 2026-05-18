class RefactorDomainRouting < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :target_controller, :string
    add_column :domains, :target_action, :string
    remove_column :domains, :html_home, :text
    remove_column :domains, :controller_action, :string
  end
end
