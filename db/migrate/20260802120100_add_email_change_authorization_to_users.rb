class AddEmailChangeAuthorizationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_change_authorized_at, :datetime
  end
end
