class CreatePasswordResetRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :password_reset_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :requested_at, null: false
      t.datetime :fulfilled_at

      t.timestamps
    end

    add_index :password_reset_requests, [:user_id, :fulfilled_at]
  end
end
